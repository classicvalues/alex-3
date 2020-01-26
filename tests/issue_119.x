-- -*- haskell -*-
{
-- Issue 119,
-- reported 2017-10-11 by Herbert Valerio Riedel,
-- fixed 2020-01-26 by Andreas Abel.
--
-- Problem was: the computed token length (in number of characters)
-- attached to AlexToken is tailored to UTF8 encoding and wrong
-- for LATIN1 encoding.

module Main where

import Control.Monad (unless)
import qualified Data.ByteString as B
import Data.Word
import System.Exit   (exitFailure)
}

%encoding "latin1"

:-

[\x01-\xff]+ { False }
[\x00]       { True  }

{
type AlexInput = B.ByteString

alexGetByte :: AlexInput -> Maybe (Word8,AlexInput)
alexGetByte = B.uncons

alexInputPrevChar :: AlexInput -> Char
alexInputPrevChar = undefined

-- generated by @alex@
alexScan :: AlexInput -> Int -> AlexReturn Bool

{-

GOOD cases:

("012\NUL3","012","\NUL3",3,3,False)
("\NUL0","\NUL","0",1,1,True)
("012","012","",3,3,False)

BAD case:

("0@P`p\128\144\160","0@P`p","",5,8,False)

expected:

("0@P`p\128\144\160","0@P`p\128\144\160","",8,8,False)

-}
main :: IO ()
main = do
    go (B.pack [0x30,0x31,0x32,0x00,0x33])                -- GOOD
    go (B.pack [0x00,0x30])                               -- GOOD
    go (B.pack [0x30,0x31,0x32])                          -- GOOD

    go (B.pack [0x30,0x40,0x50,0x60,0x70,0x80,0x90,0xa0]) -- WAS: BAD
  where
    go inp = do
      case (alexScan inp 0) of
        -- expected invariant: len == B.length inp - B.length inp'
        AlexToken inp' len b -> do
          let diff = B.length inp - B.length inp'
          unless (len == diff) $ do
            putStrLn $ "ERROR: reported length and consumed length differ!"
            print (inp, B.take len inp, inp', len, diff, b)
            exitFailure
        _ -> undefined
}
