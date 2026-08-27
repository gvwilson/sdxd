method Triple(x: int) returns (r: int)
    requires 15 < x < 20
    ensures r == 3 * x
{
    if x == 0 {
        r := 0;
    } else {
        var y := 2 * x;
        r := x + y;
    }
    assert r == 3 * x;
}

method Caller() {
    var t := Triple(18);
    assert t < 100;
}