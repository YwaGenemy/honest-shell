#!/usr/bin/env bash
# Прогон всех тестов. Сборка + сравнение вывода с ожидаемым.
#   bash helpers/tests/run.sh
set -u
cd "$(dirname "$0")/.."           # → helpers/

g++ -O2 -std=c++20 honest-updates-sort.cpp -o honest-updates-sort || { echo "СБОРКА УПАЛА"; exit 1; }

pass=0; fail=0
for in in tests/*.in; do
    base="${in%.in}"
    args="$(cat "$base.args")"
    got="$(./honest-updates-sort $args < "$in")"
    want="$(cat "$base.out")"
    if [ "$got" = "$want" ]; then
        echo "✓ $(basename "$base")"
        pass=$((pass+1))
    else
        echo "✗ $(basename "$base")"
        echo "  --- ожидалось ---"; echo "$want" | sed 's/^/  /'
        echo "  --- получено  ---"; echo "$got"  | sed 's/^/  /'
        fail=$((fail+1))
    fi
done
echo "───"
echo "passed: $pass, failed: $fail"
[ "$fail" -eq 0 ]
