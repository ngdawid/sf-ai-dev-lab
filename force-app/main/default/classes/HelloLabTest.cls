@IsTest
private class HelloLabTest {
  @IsTest
  static void greetsByName() {
    Assert.areEqual('Hello Lab', HelloLab.greet('Lab'));
  }
}
