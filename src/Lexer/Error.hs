module Lexer.Error (
  Error(..),
  ErrorType(..),
) where

import Lexer.Point

data Error = Error ErrorType Message Point Source deriving (Eq, Show)

data ErrorType = LexicographicalError | GrammaticalError | SemanticError deriving (Eq, Show)

type Message = String

type Source = String