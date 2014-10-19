
-- | Extra functions for "Control.Exception".
--   These functions provide looping, list operations and booleans.
-- If you need a wider selection of monad loops and list generalisations,
-- see <http://hackage.haskell.org/package/monad-loops>
module Control.Monad.Extra(
    module Control.Monad,
    whenJust,
    unit,
    partitionM, concatMapM, mapMaybeM,
    loopM, whileM,
    whenM, unlessM,
    ifM, notM, (||^), (&&^), orM, andM, anyM, allM,
    findM, firstJustM
    ) where

import Control.Monad
import Control.Applicative
import Data.Maybe

-- General utilities

-- | Perform some operation on 'Just', given the field inside the 'Just'.
--
-- > whenJust Nothing  print == return ()
-- > whenJust (Just 1) print == print 1
whenJust :: Applicative m => Maybe a -> (a -> m ()) -> m ()
whenJust mg f = maybe (pure ()) f mg

-- | The identity function which requires the inner argument to be '()'. Useful for functions
--   with overloaded return times.
--
-- > \(x :: Maybe ()) -> unit x == x
unit :: m () -> m ()
unit = id

-- Data.List for Monad

-- | A version of 'partition' that works with a monadic predicate.
--
-- > partitionM (Just . even) [1,2,3] == Just ([2], [1,3])
-- > partitionM (const Nothing) [1,2,3] == Nothing
partitionM :: Monad m => (a -> m Bool) -> [a] -> m ([a], [a])
partitionM f [] = return ([], [])
partitionM f (x:xs) = do
    res <- f x
    (as,bs) <- partitionM f xs
    return ([x | res]++as, [x | not res]++bs)


-- | A version of 'concatMap' that works with a monadic predicate.
concatMapM :: Monad m => (a -> m [b]) -> [a] -> m [b]
concatMapM f = liftM concat . mapM f

-- | A version of 'mapMaybe' that works with a monadic predicate.
mapMaybeM :: Monad m => (a -> m (Maybe b)) -> [a] -> m [b]
mapMaybeM f = liftM catMaybes . mapM f

-- Looping

-- | A looping operation, where the predicate returns 'Left' as a seed for the next loop
--   or 'Right' to abort the loop.
loopM :: Monad m => (a -> m (Either a b)) -> a -> m b
loopM act x = do
    res <- act x
    case res of
        Left x -> loopM act x
        Right v -> return v

-- | Keep running an operation until it becomes 'False'.
whileM :: Monad m => m Bool -> m ()
whileM act = do
    b <- act
    when b $ whileM act

-- Booleans

whenM :: Monad m => m Bool -> m () -> m ()
whenM b t = ifM b t (return ())

unlessM :: Monad m => m Bool -> m () -> m ()
unlessM b f = ifM b (return ()) f

ifM :: Monad m => m Bool -> m a -> m a -> m a
ifM b t f = do b <- b; if b then t else f

notM :: Functor m => m Bool -> m Bool
notM = fmap not

-- > Just False &&^ undefined == Just False
-- > Just True &&^ Just True == Just True
(||^), (&&^) :: Monad m => m Bool -> m Bool -> m Bool
(||^) a b = ifM a (return True) b
(&&^) a b = ifM a b (return False)

anyM :: Monad m => (a -> m Bool) -> [a] -> m Bool
anyM p [] = return False
anyM p (x:xs) = ifM (p x) (return True) (anyM p xs)

allM :: Monad m => (a -> m Bool) -> [a] -> m Bool
allM p [] = return True
allM p (x:xs) = ifM (p x) (allM p xs) (return False)

orM :: Monad m => [m Bool] -> m Bool
orM = anyM id

andM :: Monad m => [m Bool] -> m Bool
andM = allM id

-- Searching

findM :: Monad m => (a -> m Bool) -> [a] -> m (Maybe a)
findM p [] = return Nothing
findM p (x:xs) = ifM (p x) (return $ Just x) (findM p xs)

firstJustM :: Monad m => (a -> m (Maybe b)) -> [a] -> m (Maybe b)
firstJustM p [] = return Nothing
firstJustM p (x:xs) = maybe (firstJustM p xs) (return . Just) =<< p x