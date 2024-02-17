return {
  s(
    "main",
    fmt('def main() -> None:\n\t{}\n\n\nif __name__ == "__main__":\n\tmain()\n\n', {
      i(0, "pass"),
    })
  ),
}
