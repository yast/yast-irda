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

# File:	modules/Irda.ycp
# Package:	Configuration of irda
# Summary:	Irda settings, input and output functions
# Authors:	Jiri Suchomel <jsuchome@suse.cz>
#
# $Id$
#
# Representation of the IrDA configuration.
# Input and output routines.
require "yast"

module Yast
  class IrdaClass < Module
    def main
      textdomain "irda"

      Yast.import "FileUtils"
      Yast.import "Progress"
      Yast.import "Service"

      # Data was modified?
      @modified = false

      # Should irda be started?
      @start = false

      # serial port used for irda
      @port = ""

      # Maximum baud rate for the IrDA serial port
      @max_baud_rate = "0"
    end

    # Read irda settings from /etc/sysconfig/irda
    # @return true when file exists
    def ReadSysconfig
      if FileUtils.Exists("/etc/sysconfig/irda")
        @port = Convert.to_string(SCR.Read(path(".sysconfig.irda.IRDA_PORT")))
        @port = "" if @port == nil

        @max_baud_rate = Convert.to_string(
          SCR.Read(path(".sysconfig.irda.IRDA_MAX_BAUD_RATE"))
        )
        @max_baud_rate = "0" if @max_baud_rate == nil
        return true
      end
      false
    end

    # Read all irda settings
    # @return true on success
    def Read
      ReadSysconfig()

      @start = Service.Status("irda") == 0

      true
    end

    # Write all irda settings
    # @return true on success
    def Write
      return true if !@modified

      # Irda read dialog caption
      caption = _("Saving IrDA Configuration")
      steps = 2

      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/2
          _("Write the settings"),
          # Progress stage 2/2
          _("Restart the service")
        ],
        [
          # Progress step 1/2
          _("Writing the settings..."),
          # Progress step 2/2
          _("Restarting service..."),
          # Progress finished
          _("Finished")
        ],
        ""
      )

      Progress.NextStage

      SCR.Write(path(".sysconfig.irda.IRDA_PORT"), @port) if @port != ""
      if @max_baud_rate != nil
        SCR.Write(path(".sysconfig.irda.IRDA_MAX_BAUD_RATE"), @max_baud_rate)
      end
      SCR.Write(path(".sysconfig.irda"), nil)

      Progress.NextStage

      Service.Stop("irda")
      if @start
        Service.Start("irda")
        Service.Enable("irda")
      else
        Service.Disable("irda")
      end

      Progress.NextStage

      true
    end

    publish :variable => :modified, :type => "boolean"
    publish :variable => :start, :type => "boolean"
    publish :variable => :port, :type => "string"
    publish :variable => :max_baud_rate, :type => "string"
    publish :function => :ReadSysconfig, :type => "boolean ()"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
  end

  Irda = IrdaClass.new
  Irda.main
end
