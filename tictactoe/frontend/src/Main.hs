{-# LANGUAGE ScopedTypeVariables, RecursiveDo #-}

import Control.Monad (replicateM, replicateM_, forM)
import Reflex.Dom
import Data.Maybe

main :: IO ()
main = mainWidget $ do
  el "h1" $ text "Tic Tac Toe"
  tictactoe

type Board = [[Maybe Marker]]

tictactoe :: MonadWidget t m => m ()
tictactoe = do
  rec board <- tictactoeBoard who
      who <- mapDyn ((\x -> if x then Marker_X else Marker_O) . even . length . catMaybes . concat) board
  dyn =<< mapDyn (\b -> displayBoard b) board
  return ()

displayBoard :: MonadWidget t m => Board -> m ()
displayBoard b = do
  el "pre" $ forM b $ \row -> el "div" $ forM row $ \cell -> text $ case cell of
                                                                         Nothing -> "-"
                                                                         Just m -> markerToString m
  return ()

tictactoeBoard :: MonadWidget t m => Dynamic t Marker -> m (Dynamic t Board)
tictactoeBoard who = el "table" $ do
  markers :: [Dynamic t [[Maybe Marker]]] <- replicateM 3 $ do
    row :: Dynamic t [Maybe Marker] <- el "tr" $ do
      markerRow :: [Dynamic t [Maybe Marker]] <- replicateM 3 $ do
        m <- elAttr "td" ("style" =: "border: 1px solid black;") $ inputWidget who
        singleM :: Dynamic t [(Maybe Marker)] <- mapDyn (:[]) m
        return singleM
      mconcatDyn markerRow
    return row
    mapDyn (:[]) row
  markersGrid :: Dynamic t [[Maybe Marker]] <- mconcatDyn markers
  return markersGrid

data Marker = Marker_X
            | Marker_O
            deriving (Show, Read, Eq, Ord)

inputWidget :: forall t m. MonadWidget t m => Dynamic t Marker -> m (Dynamic t (Maybe Marker))
inputWidget who = do
  rec edit <- buttonDyn dynamicLabel
      let makeMark :: Event t Marker = tag (current who) edit
      marker <- holdDyn Nothing $ fmap Just makeMark
      dynamicLabel <- mapDyn (maybe " " markerToString) marker
  return marker

markerToString :: Marker -> String
markerToString m = case m of
                        Marker_X -> "X"
                        Marker_O -> "O"
buttonDyn :: MonadWidget t m => Dynamic t String -> m (Event t ())
buttonDyn ds = do
  (b, _) <- el' "button" $ dynText ds
  return $ domEvent Click b

