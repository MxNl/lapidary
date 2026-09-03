# Check that an object satisfies the `gwl_ts` contract

Unlike
[`validate_gwl_ts()`](https://mxnl.github.io/lapidary/reference/validate_gwl_ts.md)
this always inspects the object even if it is not classed as `gwl_ts`,
which makes it useful inside readers.

## Usage

``` r
check_gwl_ts(x, arg = rlang::caller_arg(x), call = rlang::caller_env())
```

## Arguments

- x:

  Object to check.

- arg:

  Argument name to use in error messages.

- call:

  Calling environment for error messages.

## Value

`TRUE`, invisibly, on success; otherwise a classed error.
