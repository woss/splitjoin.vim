require 'spec_helper'

describe "javascript" do
  let(:filename) { 'test.js' }

  before :each do
    vim.set(:expandtab)
    vim.set(:shiftwidth, 2)
  end

  after(:each) do
    vim.command('let g:splitjoin_javascript_if_clause_curly_braces = "SJ"')
  end

  specify "object literals" do
    set_file_contents "{ one: two, 'three': four }"

    vim.search '{'
    split

    assert_file_contents <<-EOF
      {
        one: two,
        'three': four
      }
    EOF

    join

    assert_file_contents "{one: two, 'three': four}"
  end

  specify "lists" do
    set_file_contents "[ 'one', 'two', 'three', 'four' ]"

    vim.search '['
    split

    assert_file_contents <<-EOF
      [
        'one',
        'two',
        'three',
        'four'
      ]
    EOF

    join

    assert_file_contents "['one', 'two', 'three', 'four']"
  end

  specify "functions" do
    set_file_contents "var foo = function() { return 'bar'; };"

    vim.search 'function'
    split

    assert_file_contents <<-EOF
      var foo = function() {
        return 'bar';
      };
    EOF

    set_file_contents <<-EOF
      var foo = function() {
        one();
        two();
        return 'bar';
      };
    EOF

    join

    assert_file_contents "var foo = function() { one(); two(); return 'bar'; };"
  end

  specify "named functions" do
    set_file_contents <<-EOF
      function example() {
        return 'bar';
      };
    EOF

    join

    assert_file_contents <<-EOF
      function example() { return 'bar'; };
    EOF
  end

  specify "arguments" do
    joined_args = "var x = foo(arg1, arg2, 'arg3', 'arg4');"
    split_args  = <<-EOF
      var x = foo(
        arg1,
        arg2,
        'arg3',
        'arg4'
      );
    EOF

    set_file_contents(split_args)
    join
    assert_file_contents(joined_args)
    split
    assert_file_contents(split_args)
  end

  specify "arguments racing with others" do
    joined_args = "function test(arg1, arg2, arg3) { return true; };"
    split_args_once  = <<-EOF
      function test(arg1, arg2, arg3) {
        return true;
      };
    EOF

    # Spec failing due to an unrelated bug with semicola - fixed with
    # the next commit
    split_args_twice = <<-EOF
      function test(
        arg1,
        arg2,
        arg3
      ) {
        return true;
      };
    EOF
    set_file_contents(joined_args)
    split
    assert_file_contents(split_args_once)
    split
    assert_file_contents(split_args_twice)
    join
    assert_file_contents(split_args_once)
    join
    assert_file_contents(joined_args)
  end

  specify "if-clauses" do
    set_file_contents <<-EOF
      if (foo) { var a = "bar"; }
    EOF

    vim.search('if')
    split

    assert_file_contents <<-EOF
      if (foo) {
        var a = "bar";
      }
    EOF

    join

    assert_file_contents <<-EOF
      if (foo) { var a = "bar"; }
    EOF

    vim.command('let g:splitjoin_javascript_if_clause_curly_braces = "sj"')

    split

    assert_file_contents <<-EOF
      if (foo)
        var a = "bar";
    EOF

    join

    assert_file_contents <<-EOF
      if (foo) var a = "bar";
    EOF
  end
end
