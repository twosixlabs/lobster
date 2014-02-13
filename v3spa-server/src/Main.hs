{-# LANGUAGE OverloadedStrings #-}
--
-- Main.hs
--
-- Copyright (C) 2013, Galois, Inc.
-- All Rights Reserved.
--

import Control.Applicative ((<$>))
import Control.Exception
import Data.Monoid ((<>))

import Lobster.Lexer (alexNoPos)
import Lobster.Error
import Lobster.JSON
import Snap

import qualified Data.Text.Lazy           as T
import qualified Data.Text.Lazy.Encoding  as E
import qualified Data.Text.Lazy.IO        as TIO

import qualified Data.Aeson.Encode.Pretty as AP

import qualified Lobster.Policy           as P

import V3SPAObject

conf :: AP.Config
conf = AP.defConfig
  { AP.confIndent  = 2
  , AP.confCompare = AP.keyOrder
                       [ "name", "class", "args", "ports"
                       , "connections", "subdomains"
                       , "left", "right", "connection"
                       ]
  }

sendVO :: V3SPAObject -> Snap ()
sendVO vo = do
  writeLBS (AP.encodePretty' conf vo)
  writeLBS "\r\n"

sendError :: Error -> Snap ()
sendError err = sendVO $ emptyVO { errors = [buildError err] }

buildError :: Error -> (ErrorLoc, String)
buildError (LocError loc err) = (loc, errorMessage err)
buildError err = (unknownLoc, errorMessage err)

handleParse :: Snap ()
handleParse = method POST $ do
  modifyResponse $ setContentType "application/json"
  body <- (T.unpack . E.decodeUtf8) <$> readRequestBody 10000000
  let policy = P.parsePolicy body
  case policy of
    Left err -> sendError err
    Right p  -> do
      case P.toDomain p of
        Left err -> sendError err
        Right (checks, dom) -> do
          sendVO $ emptyVO { checkResults = checks
                           , domain = Just dom
                           }

site :: Snap ()
site = route [("/parse", handleParse)]

main :: IO ()
main = quickHttpServe site
