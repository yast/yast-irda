# encoding: utf-8

#  Read.ycp
#  Test of Irda::Read function
#  Author: Jiri Suchomel <jsuchome@suse.cz>
#  $Id$
module Yast
  class ReadClient < Client
    def main
      # testedfiles: Irda.ycp Service.ycp
      Yast.import "Testsuite"
      Yast.import "Irda"

      @READ = {
        "init"   => { "scripts" => { "exists" => true } },
        # no sysconfig file
        "target" => { "stat" => {} }
      }

      Testsuite.Dump("==== reading... ============================")

      Testsuite.Test(lambda { Irda.Read }, [@READ, {}, {}], 0)

      Testsuite.Dump("============================================")

      @READ = {
        "init"      => { "scripts" => { "exists" => true } },
        "target"    => { "stat" => { "isreg" => true } },
        "sysconfig" => {
          "irda" => { "IRDA_PORT" => "/dev/ttyS1", "IRDA_MAX_BAUD_RATE" => nil }
        }
      }

      Testsuite.Test(lambda { Irda.Read }, [@READ, {}, {}], 0)

      nil
    end
  end
end

Yast::ReadClient.new.main
