# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006-2012 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	clients/irda.ycp
# Package:	Configuration of irda
# Summary:	Main file
# Authors:	Jiri Suchomel <jsuchome@suse.cz>
#
# $Id$
#
# Main file for irda configuration. Uses all other files.
module Yast
  class IrdaClient < Client
    def main
      Yast.import "UI"

      #**
      # <h3>Configuration of irda</h3>

      textdomain "irda"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("Irda module started")

      Yast.import "CommandLine"
      Yast.import "Irda"

      Yast.include self, "irda/ui.rb"

      @cmdline_description = {
        "id"         => "irda",
        # Command line help text for the Xirda module
        "help"       => _(
          "Configuration of IrDA"
        ),
        "guihandler" => fun_ref(method(:IrDASequence), "symbol ()"),
        "initialize" => fun_ref(Irda.method(:Read), "boolean ()"),
        "finish"     => fun_ref(Irda.method(:Write), "boolean ()"),
        "actions"    => {
          "enable"    => {
            "handler" => fun_ref(method(:IrdaEnableHandler), "boolean (map)"),
            # command line help text for 'enable' action
            "help"    => _(
              "Enable IrDA"
            )
          },
          "disable"   => {
            "handler" => fun_ref(method(:IrdaDisableHandler), "boolean (map)"),
            # command line help text for 'disable' action
            "help"    => _(
              "Disable IrDA"
            )
          },
          "configure" => {
            "handler" => fun_ref(
              method(:IrdaChangeConfiguration),
              "boolean (map)"
            ),
            # command line help text for 'configure' action
            "help"    => _(
              "Change the IrDA configuration"
            )
          }
        },
        "options"    => {
          "port" => {
            # command line help text for the 'port' option
            "help" => _(
              "Serial port"
            ),
            "type" => "string"
          }
        },
        "mappings"   => {
          "enable"    => ["port"],
          "disable"   => [],
          "configure" => ["port"]
        }
      }


      # main ui function
      @ret = CommandLine.Run(@cmdline_description)

      Builtins.y2debug("ret=%1", @ret)

      # Finish
      Builtins.y2milestone("Irda module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end

    # --------------------------------------------------------------------------
    # --------------------------------- cmd-line handlers

    # Command line handler for changing basic configuration
    # @param [Hash] options  a list of parameters passed as args
    # (currently only "port" key is expected)
    # @return [Boolean] true on success
    def IrdaChangeConfiguration(options)
      options = deep_copy(options)
      port = Ops.get_string(options, "port", "")
      if port != ""
        Irda.port = port
        Irda.modified = true
        return true
      end
      false
    end

    # Command line handler for enabling IrDA
    # @param [Hash] options  a list of parameters passed as args
    def IrdaEnableHandler(options)
      options = deep_copy(options)
      ret = IrdaChangeConfiguration(options)
      if !Irda.start
        Irda.start = true
        ret = true
        Irda.modified = true
      end
      ret
    end

    # Command line handler for disabling IrDA
    def IrdaDisableHandler(options)
      options = deep_copy(options)
      if Irda.start
        Irda.start = false
        Irda.modified = true
        return true
      end
      false
    end
  end
end

Yast::IrdaClient.new.main
