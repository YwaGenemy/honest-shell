// honest-updates-sort — фильтр + сортировка списка обновлений пакетов.
//
// Панель (Updates.qml) вызывает этот бинарник как процесс: подаёт список пакетов
// в stdin, передаёт флаги, читает отсортированный результат из stdout.
//
// Сборка:  g++ -O2 -std=c++20 honest-updates-sort.cpp -o honest-updates-sort
// Тесты:   bash helpers/tests/run.sh
//
// ── ФОРМАТ ВВОДА (stdin), по строке на пакет ────────────────────────────────
//   <имя> <старая_версия> -> <новая_версия> <источник>
//   источник = repo | aur          пример:  linux 6.15.1 -> 6.15.2 repo
//
// ── ФЛАГИ (argv) ────────────────────────────────────────────────────────────
//   --filter=all|repo|aur      какие пакеты оставить     (по умолчанию all)
//   --sort=name|version|source ключ сортировки           (по умолчанию name)
//   --order=asc|desc           направление               (по умолчанию asc)
//
// ── ФОРМАТ ВЫВОДА (stdout) ──────────────────────────────────────────────────
//   те же строки, отфильтрованные и отсортированные. Битые строки пропускаем.

#include <iostream>
#include <string>
#include <string_view>
#include <vector>
#include <algorithm>
#include <optional>
#include <sstream>

// enum class — значения живут в своей области (Filter::repo, Source::repo),
// поэтому одноимённые константы в разных enum не конфликтуют.
enum class Filter  { all, repo, aur };
enum class SortKey { name, version, source };
enum class Order   { asc, desc };
enum class Source  { repo, aur };

struct Pkg {
    std::string name;
    std::string old_v;
    std::string new_v;
    Source      source;
};
using OptPkg = std::optional<Pkg>;

struct Args {
    Filter  filter = Filter::all;
    SortKey sort   = SortKey::name;
    Order   order  = Order::asc;
};

// Если arg начинается с key ("--filter="), вернуть остаток (значение).
static std::optional<std::string_view> valueOf(std::string_view arg, std::string_view key) {
    if (arg.size() >= key.size() && arg.substr(0, key.size()) == key)
        return arg.substr(key.size());
    return std::nullopt;
}

Args ParseArgs(int argc, char** argv) {
    Args a;
    for (int i = 1; i < argc; ++i) {
        std::string_view s = argv[i];
        if (auto v = valueOf(s, "--filter=")) {
            if      (*v == "all")  a.filter = Filter::all;
            else if (*v == "repo") a.filter = Filter::repo;
            else if (*v == "aur")  a.filter = Filter::aur;
        } else if (auto v = valueOf(s, "--sort=")) {
            if      (*v == "name")    a.sort = SortKey::name;
            else if (*v == "version") a.sort = SortKey::version;
            else if (*v == "source")  a.sort = SortKey::source;
        } else if (auto v = valueOf(s, "--order=")) {
            if      (*v == "asc")  a.order = Order::asc;
            else if (*v == "desc") a.order = Order::desc;
        }
    }
    return a;
}

// Разобрать строку "имя старая -> новая источник". nullopt, если формат не тот.
OptPkg ParseLine(const std::string& line) {
    std::istringstream is(line);
    std::string name, old_v, arrow, new_v, src;
    if (!(is >> name >> old_v >> arrow >> new_v >> src))
        return std::nullopt;                 // меньше 5 полей → битая
    if (arrow != "->")
        return std::nullopt;                 // нет разделителя версий

    Source s;
    if      (src == "repo") s = Source::repo;
    else if (src == "aur")  s = Source::aur;
    else return std::nullopt;                // неизвестный источник

    return Pkg{ std::move(name), std::move(old_v), std::move(new_v), s };
}

// Сравнить версии как последовательности чисел, разделённых . - _ :
// Возвращает <0, 0, >0. Компоненты сравниваются как ЧИСЛА: "6.15.10" > "6.15.2".
int cmpVersion(std::string_view a, std::string_view b) {
    auto isSep = [](char c) { return c == '.' || c == '-' || c == '_' || c == ':'; };
    std::size_t i = 0, j = 0;

    while (i < a.size() || j < b.size()) {
        long na = 0, nb = 0;
        while (i < a.size() && !isSep(a[i])) {          // очередной компонент a
            if (a[i] >= '0' && a[i] <= '9') na = na * 10 + (a[i] - '0');
            ++i;
        }
        while (j < b.size() && !isSep(b[j])) {          // очередной компонент b
            if (b[j] >= '0' && b[j] <= '9') nb = nb * 10 + (b[j] - '0');
            ++j;
        }
        if (na != nb) return na < nb ? -1 : 1;
        if (i < a.size()) ++i;                          // пропустить разделитель
        if (j < b.size()) ++j;
    }
    return 0;
}

static const char* sourceStr(Source s) { return s == Source::repo ? "repo" : "aur"; }

int main(int argc, char** argv) {
    const Args args = ParseArgs(argc, argv);

    std::vector<Pkg> pkgs;
    std::string line;
    while (std::getline(std::cin, line))
        if (OptPkg p = ParseLine(line))                 // взять только успешно разобранные
            pkgs.push_back(std::move(*p));

    // Фильтрация — один проход, O(n)
    if (args.filter != Filter::all) {
        const Source want = (args.filter == Filter::repo) ? Source::repo : Source::aur;
        pkgs.erase(std::remove_if(pkgs.begin(), pkgs.end(),
                                  [&](const Pkg& p) { return p.source != want; }),
                   pkgs.end());
    }

    // Сортировка. Первичный ключ — по флагу и направлению; при равенстве
    // вторичный ключ — имя, ВСЕГДА по возрастанию (не зависит от order).
    std::stable_sort(pkgs.begin(), pkgs.end(), [&](const Pkg& x, const Pkg& y) {
        int c = 0;
        switch (args.sort) {
            case SortKey::name:    c = x.name.compare(y.name); break;
            case SortKey::version: c = cmpVersion(x.new_v, y.new_v); break;
            case SortKey::source:  c = std::string_view(sourceStr(x.source))
                                          .compare(sourceStr(y.source)); break;
        }
        if (args.order == Order::desc) c = -c;
        if (c != 0) return c < 0;
        return x.name < y.name;                         // тай-брейк — имя по возрастанию
    });

    for (const Pkg& p : pkgs)
        std::cout << p.name << ' ' << p.old_v << " -> " << p.new_v
                  << ' ' << sourceStr(p.source) << '\n';
    return 0;
}
