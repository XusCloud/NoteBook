console.time("start");

function func(l) {
    let e = 0;
    l.forEach((p) => {
        e ^= p;
    });

    let x = e & (-e + 1);
    let y = 0;
    l.forEach((p) => {
        if ((p & x) == 0) {
            y ^= p;
        }
    });
    let z = y ^ e;
    return [y, z];
}

const res = func([
    234, 45, 234, 888, 1000, 45, 888, 1000, 888, 45, 888, 234, 999, 888, 234, 999,
]);
console.log(res);
// 888 45

console.timeEnd("start");