# encoding: utf-8

#  Write.ycp
#  Test of Irda::Write function
#  Author: Jiri Suchomel <jsuchome@suse.cz>
#  $Id$
module Yast
  class WriteClient < Client
    def main
      # testedfiles: Irda.ycp Service.ycp
      Yast.import "Testsuite"
      Yast.import "Irda"

      @READ = {
        "init"   => {
          "scripts" => {
            "exists"   => true,
            "runlevel" => { "irda" => { "start" => [3] } },
            "comment"  => {}
          }
        },
        "target" => { "stat" => { "isreg" => true } }
      }

      @EX = {
        "target" => {
          "bash_output" => { "exit" => 0 },
          "bash"        => 0,
          "symlink"     => true
        }
      }

      Testsuite.Dump("==== nothing modified: =====================")

      Testsuite.Test(lambda { Irda.Write }, [@READ, {}, @EX], 0)

      Irda.modified = true

      Testsuite.Dump("==== stop irda: ============================")

      Testsuite.Test(lambda { Irda.Write }, [@READ, {}, @EX], 0)

      Testsuite.Dump("==== start irda, create link: ==============")

      Irda.start = true
      Irda.port = "new_port"
      Ops.set(@READ, ["init", "scripts", "runlevel"], {})

      Testsuite.Test(lambda { Irda.Write }, [@READ, {}, @EX], 0)

      nil
    end
  end
end

Yast::WriteClient.new.main
