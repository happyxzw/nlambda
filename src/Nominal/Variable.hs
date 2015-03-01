module Nominal.Variable where

import Data.Maybe (isNothing)
import Data.Time.Clock.POSIX (POSIXTime)

----------------------------------------------------------------------------------------------------
-- Variable
----------------------------------------------------------------------------------------------------

type Timestamp = POSIXTime
data Variable = Var String | QuantificationVariable Int | IterationVariable Int Int (Maybe Timestamp) deriving (Eq, Ord)

----------------------------------------------------------------------------------------------------
-- Variable name
----------------------------------------------------------------------------------------------------

digits :: Integral x => x -> [x]
digits 0 = []
digits x = digits (x `div` 10) ++ [x `mod` 10]

variableNameWithIndex :: Int -> Int -> String
variableNameWithIndex charIndex varIndex = toEnum charIndex : fmap (toEnum . (+ 8320)) (digits varIndex)

variableNameAsciiWithIndex :: Int -> Int -> String
variableNameAsciiWithIndex charIndex varIndex = toEnum charIndex : '_' : show varIndex

createVariableName :: (Int -> Int -> String) -> Variable -> String
createVariableName _ (Var name) = name
createVariableName indexName (QuantificationVariable index) = indexName 120 index
createVariableName indexName (IterationVariable level index _) = indexName (97 + level) index

variableName :: Variable -> String
variableName = createVariableName variableNameWithIndex

variableNameAscii :: Variable -> String
variableNameAscii = createVariableName variableNameAsciiWithIndex

instance Show Variable where
    show = variableName

----------------------------------------------------------------------------------------------------
-- Variable constructors
----------------------------------------------------------------------------------------------------

variable :: String -> Variable
variable = Var

quantificationVariable :: Int -> Variable
quantificationVariable = QuantificationVariable

iterationVariable :: Int -> Int -> Variable
iterationVariable level index = IterationVariable level index Nothing

iterationVariablesList :: Int -> Int -> [Variable]
iterationVariablesList level size = fmap (iterationVariable level) [1..size]

----------------------------------------------------------------------------------------------------
-- Operations on iteratation variables
----------------------------------------------------------------------------------------------------

onlyForIteration :: a -> (Int -> Int -> Maybe Timestamp -> a) -> Variable -> a
onlyForIteration result _ (Var _) = result
onlyForIteration result _ (QuantificationVariable _) = result
onlyForIteration _ f (IterationVariable level index timestamp) = f level index timestamp

setTimestamp :: Timestamp -> Variable -> Variable
setTimestamp t v = onlyForIteration v (\l i _ -> IterationVariable l i (Just t)) v

hasNoTimestamp :: Variable -> Bool
hasNoTimestamp = onlyForIteration True (\_ _ t -> isNothing t)

hasTimestampEquals :: Timestamp -> Variable -> Bool
hasTimestampEquals t = onlyForIteration False (\_ _ vt -> maybe False (== t) vt)

getTimestampNotEqual :: Timestamp -> Variable -> Maybe Timestamp
getTimestampNotEqual t = onlyForIteration Nothing (\_ _ vt -> if maybe False (/= t) vt then vt else Nothing)

clearTimestamp :: Variable -> Variable
clearTimestamp v = onlyForIteration v (\l i _ -> iterationVariable l i) v

getIterationLevel :: Variable -> Maybe Int
getIterationLevel = onlyForIteration Nothing (\l _ _ -> Just l)

setIterationLevel :: Int -> Variable -> Variable
setIterationLevel level v = onlyForIteration v (\l i t -> IterationVariable level i t) v

changeIterationLevel :: (Int -> Int) -> Variable -> Variable
changeIterationLevel f v = onlyForIteration v (\l i t -> IterationVariable (f l) i t) v
