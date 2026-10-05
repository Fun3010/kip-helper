data class GuideModule(val id: String, val title: String, val sections: List<String>)
val modules = listOf(
    GuideModule("signal", "4–20 мА", listOf("Расчёт", "Диапазон")),
    GuideModule("sipart", "SIPART PS2", listOf("Документация")),
)

fun signal(value: Double, lower: Double, upper: Double): Double {
    require(listOf(value, lower, upper).all { it.isFinite() } && upper > lower)
    require(value in lower..upper)
    return 4 + 16 * (value - lower) / (upper - lower)
}

fun main() {
    for (c in listOf(listOf(0.0, 0.0, 100.0, 4.0), listOf(50.0, 0.0, 100.0, 12.0), listOf(100.0, 0.0, 100.0, 20.0), listOf(-25.0, -50.0, 50.0, 8.0))) {
        check(kotlin.math.abs(signal(c[0], c[1], c[2]) - c[3]) < 1e-9)
    }
    for (c in listOf(listOf(0.0, 0.0, 0.0), listOf(0.0, 100.0, 0.0), listOf(101.0, 0.0, 100.0), listOf(Double.NaN, 0.0, 100.0), listOf(0.0, 0.0, Double.POSITIVE_INFINITY))) {
        check(runCatching { signal(c[0], c[1], c[2]) }.exceptionOrNull() is IllegalArgumentException)
    }
    check(modules.map { it.id }.toSet().size == modules.size)
    println("Kotlin: 10 checks passed")
}
