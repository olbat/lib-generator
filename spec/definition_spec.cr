require "./spec_helper"
require "tempfile"

describe "LibGenerator::Definition" do
  describe "initialize" do
    it "creates a new definition" do
      LibGenerator::Definition.new
    end

    it "loads from YAML" do
      LibGenerator::Definition.from_yaml(
        <<-EOS
        ---
        includes: [ foo.h ]
        prefixes: [ foo_ ]
        description: Foo definition
        EOS
      )
    end

    it "loads from JSON" do
      LibGenerator::Definition.from_json(
        <<-EOS
        {
          "includes" : [ "foo.h" ],
          "prefixes" : [ "foo_" ],
          "description" : "Foo definition"
        }
        EOS
      )
    end

    it "loads from Crystal" do
      LibGenerator::Definition.from_crystal(
        <<-EOS
        @[Include("foo.h", prefix: "foo_")]
        lib LibFoo
        end
        EOS
      )
    end
  end

  describe "parse_lib" do
    it "parses C headers specifying prefixes" do
      Tempfile.open("foo.h") do |file|
        File.write(file.path,
          <<-EOS
          int foo_foo(void *a, int b);
          void foo_bar(int a, void *b);
          int bar_foo();
          EOS
        )

        definition = LibGenerator::Definition.new(
          includes: [file.path], prefixes: ["foo_"])

        definition.parse_lib.to_s.strip.should eq(
          <<-EOS
          fun foo_foo(a : Pointer(Void), b : LibC::Int) : LibC::Int
          fun foo_bar(a : LibC::Int, b : Pointer(Void))
          EOS
        )
      end
    end

    it "parses C headers specifying flags" do
      Tempfile.open("foo.h") do |file|
        File.write(file.path,
          <<-EOS
          #ifdef __FOO
          int foo_foo();
          #else
          void foo_bar();
          #endif
          EOS
        )

        definition = LibGenerator::Definition.new(
          includes: [file.path], prefixes: ["foo_"], flags: ["-D__FOO"])

        definition.parse_lib.to_s.strip.should eq(
          <<-EOS
          fun foo_foo : LibC::Int
          EOS
        )
      end
    end

    it "raises if @includes is not defined" do
      expect_raises do
        LibGenerator::Definition.new(prefixes: ["foo_"]).parse_lib
      end
      expect_raises do
        LibGenerator::Definition.new(includes: [] of String,
          prefixes: ["foo_"]).parse_lib
      end
    end

    it "raises if @prefixes is not defined" do
      expect_raises do
        LibGenerator::Definition.new(includes: ["foo.h"]).parse_lib
      end
      expect_raises do
        LibGenerator::Definition.new(includes: ["foo.h"],
          prefixes: [] of String).parse_lib
      end
    end
  end
end
