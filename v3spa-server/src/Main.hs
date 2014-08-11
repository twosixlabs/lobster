{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings #-}
--
-- Main.hs
--
-- Copyright (C) 2013, Galois, Inc.
-- All Rights Reserved.
--
-- Released under the "BSD3" license.  See the file "LICENSE"
-- for details.
--

import Control.Monad.Reader
import Data.Aeson
import Snap

import V3SPA.Server.Snap
import V3SPA.Server.Parse
import V3SPA.Server.Paths
import V3SPA.Server.Import.SELinux
import V3SPA.Server.Import.IPTables
import V3SPA.Server.Export.SELinux

----------------------------------------------------------------------
-- Request Handlers

-- | "GET /version" --- request web service version
handleVersion :: V3Snap ()
handleVersion = method GET $ respond Null

----------------------------------------------------------------------
-- Routing and Main

-- | Routing information for the web service.
site :: V3Snap ()
site = route
  [ ("/parse",           handleParse)
  , ("/paths",           handlePaths)
  , ("/version",         handleVersion)
  , ("/import/iptables", handleImportIptables)
  , ("/import/selinux",  handleImportSELinux)
  , ("/export/selinux",  handleExportSELinux)
  ]

handler opts = do
  extendTimeout 120
  runReaderT (runV3Snap site) opts

main :: IO ()
main = do
  let options = defaultOptions
  quickHttpServe (handler options)
