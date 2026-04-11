module Spec.LibSpec (tests) where

import Lib
import Test.Sandwich

tests :: TopSpec
tests = describe "Lib" do
  it "returns greeting" do
    greeting `shouldBe` "Hello, World!"
