{-# LANGUAGE DuplicateRecordFields #-}

module Syntax.AST(
         AnnProgram(..), Program,
         AnnDeclaration(..), Declaration,
         AnnSignature(..), Signature,
         AnnConstraint(..), Constraint,
         AnnExpr(..), Expr,
         eraseAnnotations, exprIsVariable, exprHeadVariable
       ) where

import Position(Position)
import Syntax.Name(QName)

data AnnProgram a = Program {
                      programDeclarations :: [AnnDeclaration a]
                    }
  deriving Eq

type Program = AnnProgram Position

-- Annotated declaration
data AnnDeclaration a = 
    DataDeclaration {
      annotation       :: a,
      dataTypeName     :: AnnExpr a,
      dataConstructors :: [AnnSignature a]
    }
  | TypeDeclaration {
      annotation :: a,
      typeName   :: AnnExpr a,
      typeValue  :: AnnExpr a
    }
  | TypeSignature {
      typeSignature :: AnnSignature a
    }
  | ValueDeclaration {
      annotation :: a,
      declLHS  :: AnnExpr a,
      declRHS  :: AnnExpr a
    }
  | ClassDeclaration {
      annotation    :: a,
      className     :: QName,
      classTypeName :: QName,
      classMethods  :: [AnnSignature a]
    }
  deriving Eq

data AnnSignature a = Signature {
                        annotation           :: a,
                        signatureName        :: QName,
                        signatureType        :: AnnExpr a,
                        signatureConstraints :: [AnnConstraint a]
                      } deriving Eq

data AnnConstraint a = Constraint {
                         annotation          :: a,
                         constraintClassName :: QName,
                         constraintTypeName  :: QName
                       } deriving Eq

-- Annotated expression
data AnnExpr a =
    EVar a QName                      -- variable
  | EInt a Integer                    -- integer constant
  | EApp a (AnnExpr a) (AnnExpr a)    -- application
  deriving Eq

type Declaration = AnnDeclaration Position
type Constraint  = AnnConstraint Position
type Signature   = AnnSignature Position
type Expr        = AnnExpr Position

--

class EraseAnnotations f where
  eraseAnnotations :: f a -> f ()

instance EraseAnnotations AnnProgram where
  eraseAnnotations (Program x) = Program (map eraseAnnotations x)

instance EraseAnnotations AnnDeclaration where
  eraseAnnotations (DataDeclaration _ x y) =
    DataDeclaration () (eraseAnnotations x) (map eraseAnnotations y)
  eraseAnnotations (TypeDeclaration _ x y) =
    TypeDeclaration () (eraseAnnotations x) (eraseAnnotations y)
  eraseAnnotations (TypeSignature x) =
    TypeSignature (eraseAnnotations x)
  eraseAnnotations (ValueDeclaration _ x y) =
    ValueDeclaration () (eraseAnnotations x) (eraseAnnotations y)
  eraseAnnotations (ClassDeclaration _ x y z) =
    ClassDeclaration () x y (map eraseAnnotations z)

instance EraseAnnotations AnnSignature where
  eraseAnnotations (Signature _ x y z) =
    Signature () x (eraseAnnotations y) (map eraseAnnotations z)

instance EraseAnnotations AnnConstraint where
  eraseAnnotations (Constraint _ x y) = Constraint () x y

instance EraseAnnotations AnnExpr where
  eraseAnnotations (EVar _ q)     = EVar () q
  eraseAnnotations (EInt _ n)     = EInt () n
  eraseAnnotations (EApp _ e1 e2) = EApp () (eraseAnnotations e1)
                                            (eraseAnnotations e2)

--

exprIsVariable :: AnnExpr a -> Bool
exprIsVariable (EVar _ _) = True
exprIsVariable _          = False

exprHeadVariable :: AnnExpr a -> Maybe QName
exprHeadVariable (EVar _ q)    = return q
exprHeadVariable (EApp _ e1 _) = exprHeadVariable e1
exprHeadVariable _             = Nothing

---- Show

joinS :: String -> [String] -> String
joinS _   []       = ""
joinS _   [l]      = l
joinS sep (l : ls) = l ++ sep ++ joinS sep ls

joinLines :: [String] -> String
joinLines = joinS "\n"

indent :: String -> String
indent s = "  " ++ s

instance Show a => Show (AnnProgram a) where
  show (Program decls) = joinS "\n\n" (map show decls)

instance Show a => Show (AnnDeclaration a) where
  show (DataDeclaration _ typ constructorDeclarations) =
    joinLines (
      ["data " ++ show typ ++ " where"] ++
      map (indent . show) constructorDeclarations
    )
  show (TypeDeclaration _ typ val) =
    "type " ++ show typ ++ " = " ++ show val
  show (TypeSignature sig) = show sig
  show (ValueDeclaration _ lhs rhs) =
    show lhs ++ " = " ++ show rhs
  show (ClassDeclaration _ name typeName methods) =
    joinLines (
      ["class " ++ show name ++ " " ++ show typeName ++ " where"] ++
      map (indent . show) methods
    )

instance Show a => Show (AnnSignature a) where
  show (Signature _ name typ constraints) =
      show name ++ " : " ++ show typ ++ showOptionalConstraints constraints

instance Show a => Show (AnnConstraint a) where
  show (Constraint _ className typeName) =
    show className ++ " " ++ show typeName

showOptionalConstraints :: Show a => [AnnConstraint a] -> String
showOptionalConstraints [] = ""
showOptionalConstraints cs = 
  indent ("{"
       ++ joinS "; " (map show cs)
       ++ "}")

instance Show (AnnExpr a) where
  show (EVar _ qname) = show qname
  show (EInt _ n)     = show n
  show (EApp _ f x)   = "(" ++ show f ++ " " ++ show x ++ ")"

