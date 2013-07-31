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

# File:	include/irda/ui.ycp
# Package:	Configuration of irda
# Summary:	Dialogs definitions
# Authors:	Jiri Suchomel <jsuchome@suse.cz>
#
# $Id$
module Yast
  module IrdaUiInclude
    def initialize_irda_ui(include_target)
      Yast.import "UI"

      textdomain "irda"

      Yast.import "Irda"
      Yast.import "Label"
      Yast.import "Message"
      Yast.import "Package"
      Yast.import "Popup"
      Yast.import "Service"
      Yast.import "Wizard"
    end

    # Popup for testing IrDA
    # @param [String] port the serial port use for IrDA
    # (to see if it was changed and service needs to be restarted)
    def TestPopup(port, baud_rate)
      modified = port != Irda.port || baud_rate != Irda.max_baud_rate
      # if service was originaly started
      orig_start = false

      # temporary start the service
      # return error output
      irda_tmp_start = lambda do
        out = {}
        orig_start = Service.Status("irda") == 0

        if modified
          # 1. save new configuration
          SCR.Write(path(".sysconfig.irda.IRDA_PORT"), port)
          SCR.Write(path(".sysconfig.irda.IRDA_MAX_BAUD_RATE"), baud_rate)
          SCR.Write(path(".sysconfig.irda"), nil)
        end

        # 2. start/restart the service
        # when module cannot be loaded, Runlevel returns 0 -> use target.bash
        if !orig_start
          out = Service.RunInitScriptOutput("irda", "start")
        elsif modified
          out = Service.RunInitScriptOutput("irda", "restart")
        end

        Ops.get_string(out, "stderr", "")
      end

      # internal function
      # return IrDA configuration to original state after testing
      irda_tmp_stop = lambda do
        if modified
          SCR.Write(path(".sysconfig.irda.IRDA_PORT"), Irda.port)
          SCR.Write(
            path(".sysconfig.irda.IRDA_MAX_BAUD_RATE"),
            Irda.max_baud_rate
          )
          SCR.Write(path(".sysconfig.irda"), nil)
        end

        if !orig_start
          Service.RunInitScript("irda", "stop")
        elsif modified
          Service.RunInitScript("irda", "restart")
        end

        nil
      end

      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1.5),
          VBox(
            VSpacing(1),
            # Wait text label
            Label(_("Initializing -- please wait...")),
            VSpacing(1),
            PushButton(Id(:done), Opt(:default), Label.CancelButton),
            VSpacing(1)
          ),
          HSpacing(1.5)
        )
      )

      start = irda_tmp_start.call
      UI.CloseDialog
      if start != ""
        Builtins.y2error("irda service returns: %1", start)
        Popup.Error(Message.CannotStartService("irda"))
        irda_tmp_stop.call
        return false
      end

      # run test application
      SCR.Execute(path(".background.run_output"), "irdadump")

      # construct the dialog
      UI.OpenDialog(
        Opt(:decorated),
        HBox(
          HSpacing(1.5),
          VSpacing(18),
          VBox(
            HSpacing(80),
            VSpacing(0.5),
            # Popup label (heading)
            Label(_("IrDA Test")),
            VSpacing(0.5),
            LogView(Id(:log), "", 8, 0),
            VSpacing(0.5),
            LogView(
              Id(:discovery),
              # log view label (log will contain english messages)
              _("Discovery log (kernel diagnostics)"),
              5,
              0
            ),
            VSpacing(0.5),
            HBox(
              PushButton(Id(:done), Opt(:key_F9), Label.CloseButton),
              PushButton(Id(:stop), Opt(:key_F5), Label.StopButton),
              PushButton(Id(:cont), Opt(:key_F6), Label.ContinueButton)
            ),
            VSpacing(0.5)
          ),
          HSpacing(1.5)
        )
      )

      # read the output of test application
      test_output = ""
      discovery = ""
      UI.ChangeWidget(Id(:cont), :Enabled, false)

      ret = nil
      begin
        ret = Convert.to_symbol(UI.PollInput)
        if Convert.to_boolean(SCR.Read(path(".background.output_open"))) &&
            Ops.greater_than(
              Convert.to_integer(SCR.Read(path(".background.newlines"))),
              0
            )
          # read the output line from irw:
          out = Convert.to_list(SCR.Read(path(".background.newout")))
          test_output = Ops.get_string(out, 0, "")
          if test_output != ""
            UI.ChangeWidget(Id(:log), :LastLine, Ops.add(test_output, "\n"))
          end
        elsif !Convert.to_boolean(SCR.Read(path(".background.output_open")))
          # error text
          Popup.Error(_("The testing application is not responding."))
          ret = :ok
        end
        disc = Convert.to_string(
          SCR.Read(path(".target.string"), "/proc/net/irda/discovery")
        )
        if disc != discovery
          discovery = disc
          UI.ChangeWidget(Id(:discovery), :Value, discovery)
        end
        if ret == :stop
          SCR.Execute(path(".background.kill"))
          UI.ChangeWidget(Id(:cont), :Enabled, true)
          UI.ChangeWidget(Id(:stop), :Enabled, false)
          ret = Convert.to_symbol(UI.UserInput)
        end
        if ret == :cont
          SCR.Execute(path(".background.run_output"), "irdadump")
          UI.ChangeWidget(Id(:stop), :Enabled, true)
          UI.ChangeWidget(Id(:cont), :Enabled, false)
          ret = nil
        end
        Builtins.sleep(100)
      end while ret == nil

      SCR.Execute(path(".background.kill"))
      irda_tmp_stop.call
      UI.CloseDialog

      true
    end


    # Dialog for seting up IrDA
    def IrDADialog
      # For translators: Caption of the dialog
      caption = _("IrDA Configuration")

      # help text for IrDA 1/4
      help = _(
        "<p>Here, configure an infrared interface (<b>IrDA</b>) for your computer.</p>"
      ) +
        # help text for IrDA 2/4
        _(
          "<p>Choose the correct serial port for <b>Port</b>. Refer to your BIOS setup to find out which is correct.</p>"
        ) +
        # help text for IrDA 3/4
        _(
          "<p>To test if it works, put your IrDA device (phone, PDA, etc.) in range of your infrared port and push <b>Test</b>.</p>"
        ) +
        # help text for IrDA 4/4
        _(
          "<p>For some mobile phones, the speed of the infrared connection must be limited. Try setting <b>Maximum Baud Rate</b> if you encounter problems.</p>"
        )

      start = Irda.start
      port = Irda.port
      baud_rate = Irda.max_baud_rate
      brate_limited = baud_rate != "0"

      ports = ["/dev/ttyS0", "/dev/ttyS1", "/dev/ttyS2", "/dev/ttyS3"]
      rates = ["9600", "19200", "38400", "57600", "115200"]

      con = HBox(
        HSpacing(3),
        VBox(
          VSpacing(2),
          RadioButtonGroup(
            Id(:rd),
            Left(
              HVSquash(
                VBox(
                  Left(
                    RadioButton(
                      Id(:no),
                      Opt(:notify),
                      # radio button label
                      _("Do No&t Start IrDA"),
                      !start
                    )
                  ),
                  Left(
                    RadioButton(
                      Id(:yes),
                      Opt(:notify),
                      # radio button label
                      _("&Start IrDA"),
                      start
                    )
                  )
                )
              )
            )
          ),
          VSpacing(),
          # frame label
          Frame(
            _("Basic IrDA Settings"),
            HBox(
              HSpacing(),
              VBox(
                VSpacing(),
                ComboBox(
                  Id(:ports),
                  Opt(:notify, :hstretch, :editable),
                  # combobox label
                  _("&Port"),
                  ports
                ),
                VSpacing(0.5),
                Right(
                  # button label
                  PushButton(Id(:test), Opt(:key_F6), _("&Test"))
                ),
                VSpacing(0.5)
              ),
              HSpacing()
            )
          ),
          VSpacing(0.5),
          # frame label
          Frame(
            _("Baud Rate Limit"),
            HBox(
              HSpacing(),
              VBox(
                VSpacing(),
                Left(
                  CheckBox(
                    Id(:limited),
                    Opt(:notify),
                    # checkbox label
                    _("&Limit Baud Rate"),
                    brate_limited
                  )
                ),
                VSpacing(0.5),
                ComboBox(
                  Id(:brate),
                  Opt(:notify, :hstretch),
                  # combobox label
                  _("&Maximum Baud Rate"),
                  rates
                ),
                VSpacing(0.5)
              ),
              HSpacing()
            )
          ),
          VStretch()
        ),
        HSpacing(3)
      )


      Wizard.SetContents(caption, con, help, true, true)

      UI.ChangeWidget(Id(:ports), :Value, port)

      Builtins.foreach([:ports, :test, :limited]) do |widget|
        UI.ChangeWidget(Id(widget), :Enabled, start)
      end

      UI.ChangeWidget(Id(:brate), :Enabled, start && brate_limited)
      if brate_limited && Builtins.contains(rates, baud_rate)
        UI.ChangeWidget(Id(:brate), :Value, baud_rate)
      end

      ret = nil
      begin
        ret = Convert.to_symbol(UI.UserInput)
        port = Convert.to_string(UI.QueryWidget(Id(:ports), :Value))

        if brate_limited
          baud_rate = Convert.to_string(UI.QueryWidget(Id(:brate), :Value))
        end
        if ret == :yes || ret == :no
          start = ret == :yes
          if start && !Package.InstalledAll(["irda"])
            if Package.InstallAll(["irda"])
              Irda.ReadSysconfig
              port = Irda.port
              UI.ChangeWidget(Id(:ports), :Value, port)
            else
              start = false
              UI.ChangeWidget(Id(:rd), :CurrentButton, :no)
            end
          end
          Builtins.foreach([:ports, :test, :limited]) do |widget|
            UI.ChangeWidget(Id(widget), :Enabled, start)
          end
          UI.ChangeWidget(Id(:brate), :Enabled, start && brate_limited)
        end
        if ret == :limited
          brate_limited = Convert.to_boolean(
            UI.QueryWidget(Id(:limited), :Value)
          )
          UI.ChangeWidget(Id(:brate), :Enabled, start && brate_limited)
          baud_rate = "0" if !brate_limited
        end
        TestPopup(port, baud_rate) if ret == :test
      end while !Builtins.contains([:back, :abort, :cancel, :next, :ok], ret)

      if (ret == :next || ret == :ok) &&
          (start != Irda.start || port != Irda.port ||
            baud_rate != Irda.max_baud_rate)
        Irda.modified = true
        Irda.start = start
        Irda.port = port
        Irda.max_baud_rate = baud_rate
      end
      ret
    end

    # Thew whole sequence
    def IrDASequence
      Wizard.OpenOKDialog
      Wizard.SetDesktopTitleAndIcon("irda")

      Irda.Read

      ret = IrDADialog()
      Irda.Write if ret == :next || ret == :finish || ret == :ok

      UI.CloseDialog
      ret
    end
  end
end
