// RUN: %target-parse-verify-swift

protocol Fooable {
  associatedtype Foo

  var foo: Foo { get }
}

protocol Barrable {
  associatedtype Bar: Fooable
  var bar: Bar { get }
}

struct X {}
struct Y: Fooable {
  typealias Foo = X
  var foo: X { return X() }
}
struct Z: Barrable {
  typealias Bar = Y
  var bar: Y { return Y() }
}

protocol TestSameTypeRequirement {
  func foo<F1: Fooable where F1.Foo == X>(_ f: F1)
}
struct SatisfySameTypeRequirement : TestSameTypeRequirement {
  func foo<F2: Fooable where F2.Foo == X>(_ f: F2) {}
}

func test1<T: Fooable where T.Foo == X>(_ fooable: T) -> X {
  return fooable.foo
}

struct NestedConstraint<T> {
  func tFoo<U: Fooable where U.Foo == T>(_ fooable: U) -> T {
    return fooable.foo
  }
}

func test2<
  T: Fooable, U: Fooable
  where
  T.Foo == X, U.Foo == T.Foo
>(_ t: T, u: U) -> (X, X) {
  return (t.foo, u.foo)
}

func test2a<
  T: Fooable, U: Fooable
  where
  T.Foo == X, T.Foo == U.Foo
>(_ t: T, u: U) -> (X, X) {
  return (t.foo, u.foo)
}

func test3<
  T: Fooable, U: Fooable
  where
  T.Foo == X, U.Foo == X, T.Foo == U.Foo
>(_ t: T, u: U) -> (X, X) {
  return (t.foo, u.foo)
}

func fail1<
  T: Fooable, U: Fooable
  where
  T.Foo == X, U.Foo == Y, T.Foo == U.Foo // expected-error{{generic parameter 'Foo' cannot be equal to both 'X' and 'Y'}}
>(_ t: T, u: U) -> (X, Y) {
  return (t.foo, u.foo)
}

func fail2<
  T: Fooable, U: Fooable
  where
  T.Foo == U.Foo, T.Foo == X, U.Foo == Y // expected-error{{generic parameter 'Foo' cannot be equal to both 'X' and 'Y'}}
>(_ t: T, u: U) -> (X, Y) {
  return (t.foo, u.foo) // expected-error{{cannot convert return expression of type 'X' to return type 'Y'}}
}

func test4<T: Barrable where T.Bar == Y>(_ t: T) -> Y {
  return t.bar
}

func fail3<
  T: Barrable
  where
  T.Bar == X // expected-error{{'X' does not conform to required protocol 'Fooable'}}
>(_ t: T) -> X {
  return t.bar // expected-error{{cannot convert return expression of type 'T.Bar' to return type 'X'}}
}

func test5<T: Barrable where T.Bar.Foo == X>(_ t: T) -> X {
  return t.bar.foo
}

func test6<T: Barrable where T.Bar == Y>(_ t: T) -> (Y, X) {
  return (t.bar, t.bar.foo)
}

func test7<T: Barrable where T.Bar == Y, T.Bar.Foo == X>(_ t: T) -> (Y, X) {
  return (t.bar, t.bar.foo)
}

func fail4<
  T: Barrable
  where
  T.Bar == Y,
  T.Bar.Foo == Z // expected-error{{generic parameter 'Foo' cannot be equal to both 'Foo' (aka 'X') and 'Z'}}
>(_ t: T) -> (Y, Z) {
  return (t.bar, t.bar.foo) // expected-error{{cannot convert return expression of type 'X' to return type 'Z'}}
}

// TODO: repeat diagnostic
func fail5<
  T: Barrable
  where
  T.Bar.Foo == Z,
  T.Bar == Y // expected-error 2{{generic parameter 'Foo' cannot be equal to both 'Z' and 'Foo'}}
>(_ t: T) -> (Y, Z) {
  return (t.bar, t.bar.foo) // expected-error{{cannot convert return expression of type 'X' to return type 'Z'}}
}

func test8<T: Fooable where T.Foo == X, T.Foo == Y>(_ t: T) {} // expected-error{{generic parameter 'Foo' cannot be equal to both 'X' and 'Y'}}

func testAssocTypeEquivalence<
  T: Fooable where T.Foo == X
>(_ fooable: T) -> X.Type {
  return T.Foo.self
}

func fail6<T where T == Int>(_ t: T) -> Int { // expected-error{{same-type requirement makes generic parameter 'T' non-generic}}
  return t // expected-error{{cannot convert return expression of type 'T' to return type 'Int'}}
}

func test8<
  T: Barrable, U: Barrable
  where
  T.Bar == Y, U.Bar.Foo == X, T.Bar == U.Bar
>(_ t: T, u: U) -> (Y, Y, X, X) {
  return (t.bar, u.bar, t.bar.foo, u.bar.foo)
}

func test8a<
  T: Barrable, U: Barrable
  where
  T.Bar == Y, U.Bar.Foo == X, U.Bar == T.Bar
>(_ t: T, u: U) -> (Y, Y, X, X) {
  return (t.bar, u.bar, t.bar.foo, u.bar.foo)
}

// rdar://problem/19137463
func rdar19137463<T where T.a == T>(_ t: T) {} // expected-error{{'a' is not a member type of 'T'}}
rdar19137463(1)


// FIXME: Terrible diagnostic

struct Brunch<U : Fooable where U.Foo == X> { } // expected-note{{requirement specified as 'U.Foo' == 'X' [with U = BadFooable]}}

struct BadFooable : Fooable {
  typealias Foo = DoesNotExist // expected-error{{use of undeclared type 'DoesNotExist'}}
  var foo: Foo { while true {} }
}

func bogusInOutError(d: inout Brunch<BadFooable>) {} // expected-error{{parameters may not have the 'var' specifier}}
// expected-error@-1{{'Brunch' requires the types '<<error type>>' and 'X' be equivalent}}

