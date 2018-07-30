{-
    Copyright 2012-2015 Vidar Holen

    This file is part of ShellCheck.
    https://www.shellcheck.net

    ShellCheck is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ShellCheck is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
-}
module ShellCheck.Formatter.Format where

import ShellCheck.Data
import ShellCheck.Interface

-- A formatter that carries along an arbitrary piece of data
data Formatter = Formatter {
    header ::  IO (),
    onResult :: CheckResult -> SystemInterface IO -> IO (),
    onFailure :: FilePath -> ErrorMessage -> IO (),
    footer :: IO ()
}

sourceFile = posFile . pcStartPos
lineNo = posLine . pcStartPos
endLineNo = posLine . pcEndPos
colNo  = posColumn . pcStartPos
endColNo = posColumn . pcEndPos
codeNo = cCode . pcComment
messageText = cMessage . pcComment

severityText :: PositionedComment -> String
severityText pc =
    case cSeverity (pcComment pc) of
        ErrorC   -> "error"
        WarningC -> "warning"
        InfoC    -> "info"
        StyleC   -> "style"

-- Realign comments from a tabstop of 8 to 1
makeNonVirtual comments contents =
    map fix comments
  where
    ls = lines contents
    fix c = c {
        pcStartPos = (pcStartPos c) {
            posColumn = realignColumn lineNo colNo c
        }
      , pcEndPos = (pcEndPos c) {
            posColumn = realignColumn endLineNo endColNo c
        }
    }
    realignColumn lineNo colNo c =
      if lineNo c > 0 && lineNo c <= fromIntegral (length ls)
      then real (ls !! fromIntegral (lineNo c - 1)) 0 0 (colNo c)
      else colNo c
    real _ r v target | target <= v = r
    real [] r v _ = r -- should never happen
    real ('\t':rest) r v target =
        real rest (r+1) (v + 8 - (v `mod` 8)) target
    real (_:rest) r v target = real rest (r+1) (v+1) target
