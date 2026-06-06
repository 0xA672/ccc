// ccc unit tests — run with: c3c test
// Note: C3 test framework can't access module functions from test modules.
// Integration tests are in scripts/test.sh instead.
module ccc_test;
import std::testing;

fn void test_smoke() @test
{
    // Smoke test — ensures test framework works
    testing::pass();
}
