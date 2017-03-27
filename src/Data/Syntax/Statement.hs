{-# LANGUAGE StandaloneDeriving #-}
module Data.Syntax.Statement where

import Prologue

-- | Conditional. This must have an else block, which can be filled with some default value when omitted in the source, e.g. 'pure ()' for C-style if-without-else or 'pure Nothing' for Ruby-style, in both cases assuming some appropriate Applicative context into which the If will be lifted.
data If a = If { condition :: !a, thenBlock :: !a, elseBlock :: !a }
  deriving (Eq, Show)


-- Returns

newtype Return a = Return a
  deriving (Eq, Show)

newtype Yield a = Yield a
  deriving (Eq, Show)


-- Exception handling

newtype Throw a = Throw a
  deriving (Eq, Show)

data Try with a = Try !a ![with a]

data Catch a = Catch !(Maybe a) !a
  deriving (Eq, Show)

newtype Finally a = Finally a
  deriving (Eq, Show)


-- Instances

deriving instance (Eq a, Eq (with a)) => Eq (Try with a)
deriving instance (Show a, Show (with a)) => Show (Try with a)
