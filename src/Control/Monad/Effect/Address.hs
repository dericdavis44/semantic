{-# LANGUAGE MultiParamTypeClasses, TypeFamilies #-}
module Control.Monad.Effect.Address where

import Prologue
import Prelude hiding (fail)
import Control.Monad.Effect.Store
import Data.Abstract.Address
import Data.Abstract.Environment
import Data.Abstract.FreeVariables
import Data.Abstract.Store
import Data.Abstract.Value

-- | 'Monad's offering 'alloc'ation and 'deref'erencing of 'Address'es.
class (Ord l, Pointed (Cell l), Monad m) => MonadAddress l m where
  deref :: (MonadStore a m, MonadFail m, l ~ LocationFor a) => Address l a -> m a

  alloc :: (MonadStore a m, l ~ LocationFor a) => Name -> m (Address l a)

-- | Look up or allocate an address for a 'Name' free in a given term & assign it a given value, returning the 'Name' paired with the address.
--
--   The term is expected to contain one and only one free 'Name', meaning that care should be taken to apply this only to e.g. identifiers.
envLookupOrAlloc' ::
                  ( FreeVariables t
                  , Semigroup (Cell (LocationFor a) a)
                  , MonadStore a m
                  , MonadAddress (LocationFor a) m
                  )
                  => t -> Environment (LocationFor a) a -> a -> m (Name, Address (LocationFor a) a)
envLookupOrAlloc' term = let [name] = toList (freeVariables term) in
                         envLookupOrAlloc name

-- | Look up or allocate an address for a 'Name' & assign it a given value, returning the 'Name' paired with the address.
envLookupOrAlloc ::
                 ( Semigroup (Cell (LocationFor a) a)
                 , MonadStore a m
                 , MonadAddress (LocationFor a) m
                 )
                 => Name -> Environment (LocationFor a) a -> a -> m (Name, Address (LocationFor a) a)
envLookupOrAlloc name env v = do
  a <- maybe (alloc name) pure (envLookup name env)
  assign a v
  pure (name, a)


-- | 'Precise' locations are always 'alloc'ated a fresh 'Address', and 'deref'erence to the 'Latest' value written.
instance Monad m => MonadAddress Precise m where
  deref = maybe uninitializedAddress (pure . unLatest) <=< flip fmap getStore . storeLookup

  alloc _ = fmap allocPrecise getStore
    where allocPrecise :: Store Precise a -> Address Precise a
          allocPrecise = Address . Precise . storeSize


-- | 'Monovariant' locations 'alloc'ate one 'Address' per unique variable name, and 'deref'erence once per stored value, nondeterministically.
instance (Alternative m, Monad m) => MonadAddress Monovariant m where
  deref = asum . maybe [] (map pure . toList) <=< flip fmap getStore . storeLookup

  alloc = pure . Address . Monovariant


-- | Fail with a message denoting an uninitialized address (i.e. one which was 'alloc'ated, but never 'assign'ed a value before being 'deref'erenced).
uninitializedAddress :: MonadFail m => m a
uninitializedAddress = fail "uninitialized address"
