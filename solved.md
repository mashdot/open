# Solved Games and Code

## Solved Games Explained

Games that have been **"solved"** are games where the optimal strategy for all positions has been mathematically determined, meaning the outcome (win, lose, or draw) can be predicted with certainty given perfect play from both sides.

### Types of Solutions

1. **Ultra-weak solution** - Proves the game-theoretic value (win/loss/draw) from the initial position, but doesn't provide the full strategy
2. **Weak solution** - Provides a strategy to achieve the optimal outcome from the starting position
3. **Strong solution** - Provides the optimal move for *every* possible position in the game

### Notable Solved Games

| Game | Year Solved | Outcome with Perfect Play |
|------|-------------|---------------------------|
| **Tic-Tac-Toe** | Trivially solved | Draw |
| **Connect Four** | 1988 | First player wins |
| **Checkers** | 2007 | Draw |
| **Nim** | 1901 | Depends on starting config |
| **Awari (Oware)** | 2002 | Draw |

### Why Some Games Remain Unsolved

Games like **Chess** and **Go** have astronomically large state spaces:
- Chess: ~10^44 possible positions
- Go: ~10^170 possible positions

These are computationally intractable to fully solve with current technology. Instead, we rely on heuristics and AI (like Stockfish or AlphaGo) that play at superhuman levels but don't represent complete solutions.

### Checkers: A Landmark Achievement

The 2007 solution of checkers by Jonathan Schaeffer's team at the University of Alberta was significant—it took 18 years of computation and proved that checkers is a **draw** with perfect play from both sides.

---

## Is There "Solved" Code?

### Where Code is "Solved"

#### 1. Standard Algorithms
Certain problems have provably optimal solutions:
- Sorting (comparison-based): O(n log n) is the theoretical minimum
- Binary search: O(log n) is optimal for sorted arrays
- Hash table lookup: O(1) average case is optimal

#### 2. Superoptimizers
These tools exhaustively search for the *shortest possible* assembly instruction sequence for small operations. For example:

```c
// "Solved" bit manipulation - no shorter sequence exists
int abs(int x) {
    int mask = x >> 31;
    return (x + mask) ^ mask;
}
```

Tools like **STOKE** and **Souper** have found optimal instruction sequences for small functions that humans couldn't improve.

#### 3. Synthesis from Specification
Program synthesis tools can generate provably correct code for small, well-specified problems—essentially "solving" them.

### Why Most Code Isn't "Solved"

| Challenge | Why It Prevents "Solving" |
|-----------|---------------------------|
| **Undecidability** | Halting problem—can't always prove program correctness |
| **Specification ambiguity** | Unlike games, "correct" code depends on fuzzy requirements |
| **Trade-offs** | Optimize for speed? Memory? Readability? Maintainability? |
| **Context dependence** | Best solution depends on data characteristics, hardware, etc. |

---

## STOKE and Souper

### STOKE

**STOKE** (Stochastic Superoptimizer) is a research project from Stanford that finds optimal or near-optimal assembly code sequences using randomized search.

#### How It Works

1. **Takes input**: A target function (C/C++ compiled to x86-64)
2. **Random mutations**: Randomly modifies instruction sequences (swap instructions, change registers, add/remove operations)
3. **Tests equivalence**: Verifies the mutated version produces the same outputs
4. **Cost function**: Scores candidates by performance (instruction count, latency, etc.)
5. **MCMC sampling**: Uses Markov Chain Monte Carlo to explore the search space efficiently

#### Key Insight

Instead of exhaustively searching all possible programs (computationally infeasible), STOKE uses **stochastic search**—random but guided exploration that often finds surprisingly good solutions.

#### Limitations

- Only works on small functions (< ~20 instructions typically)
- Requires extensive testing to verify correctness
- Search can take hours/days

### Souper

**Souper** is a superoptimizer from the University of Utah that works at the **LLVM IR level** (intermediate representation), making it language-agnostic.

#### How It Works

1. **Harvests patterns**: Extracts expression trees from LLVM IR
2. **Queries SMT solver**: Uses Z3 or similar to prove equivalence between original and optimized versions
3. **Synthesizes replacements**: Generates simpler equivalent expressions

#### Key Difference from STOKE

| Aspect | STOKE | Souper |
|--------|-------|--------|
| **Level** | x86-64 assembly | LLVM IR |
| **Method** | Stochastic search | SMT-based synthesis |
| **Correctness** | Testing (probabilistic) | Formal proof (guaranteed) |
| **Speed** | Faster exploration | Slower but exhaustive |

#### Practical Use

Souper has been used to **find missing optimizations in LLVM itself**—patterns the compiler should optimize but doesn't. These findings get upstreamed as new compiler optimizations.

---

## JavaScript Superoptimization

There's nothing as mature as STOKE or Souper for JavaScript.

### Why JavaScript is Harder

| Challenge | Explanation |
|-----------|-------------|
| **Dynamic typing** | Can't reason statically about `x + y` without knowing types |
| **Complex semantics** | Coercion rules, prototype chains, `this` binding are notoriously complex |
| **Runtime dependence** | Performance depends on JIT (V8, SpiderMonkey) heuristics, not instruction count |
| **No stable IR** | V8's internal representations change frequently |

### What Does Exist

1. **Prepack** (Facebook, now abandoned) - Partially evaluated JavaScript at build time
2. **Google Closure Compiler** (Advanced Mode) - Aggressive transformations but not exhaustive search
3. **esbuild / terser / uglify** - Minifiers that apply known-good transformations
4. **JIT Compilers Themselves** - V8's TurboFan optimizes hot paths based on runtime type feedback

For JavaScript, the ecosystem has settled on "good enough" minification + JIT optimization at runtime rather than compile-time superoptimization.

---

## Why Engineers Disagree on "Best" Code

### Different Optimization Targets

```javascript
// Engineer A: "Optimize for readability"
const adults = users.filter(u => u.age >= 18);

// Engineer B: "Optimize for performance"
const adults = [];
for (let i = 0; i < users.length; i++) {
  if (users[i].age >= 18) adults.push(users[i]);
}

// Engineer C: "Optimize for immutability/FP style"
const adults = users.reduce((acc, u) => 
  u.age >= 18 ? [...acc, u] : acc, []);
```

All "correct." All "best" by different criteria.

### Context & Experience

| Background | Likely Preference |
|------------|-------------------|
| Came from Java | Classes, OOP patterns |
| Came from Haskell | Functional, immutable |
| Performance-critical systems | Micro-optimizations |
| Startup/ship fast | Whatever works |
| Burned by bugs | Defensive, verbose |

### Trade-off Axes

```
Readability ←───────────→ Performance
Conciseness ←───────────→ Explicitness
Flexibility ←───────────→ Type Safety
DRY         ←───────────→ Clarity
Clever      ←───────────→ Obvious
```

Engineers weight these differently.

### Where Consensus Can Exist

- **Correctness**: Code that has bugs is objectively worse
- **Big-O complexity**: O(n) beats O(n²) for large inputs (usually)
- **Security**: Don't eval user input, sanitize SQL, etc.
- **Established patterns in a codebase**: Consistency matters

---

## Bottom Line

There's no "solved" state for most code because **there's no single objective function to optimize**. 

Games have:
- Clear rules
- Clear win condition
- Complete information

Code has:
- Fuzzy requirements
- Multiple competing goals
- Future unknown changes
- Human readers with different brains

Two brilliant engineers can look at the same code and reasonably disagree on the "best" path—and both be right within their value systems. This is why code review often becomes negotiation rather than truth-finding.
