---
title: Compile-time exhaustiveness checks in TypeScript
description: A guide to checking at compile-time that TypeScript code contains if/else branches for every possible input
slug: blog/exhaustiveness-checks-in-typescript
author: David Hofmann
pubDate: 2024-01-14
lastUpdated~: 2024-01-14
---

David Hofmann | 2024-01-14

![](../../../../public/blog/high-resolution/exhaustiveness-checks-in-typescript-banner-1920-50.jpg)

Exhaustiveness checks make sure that there is a suitable `if`/`else` or `switch`/`case` branch for every possible input that a function might process. Without these safeguards, unexpected input can lead to silent failures that are hard to spot. In TypeScript, exhaustiveness can be checked through the type system to identify missing code paths right at compile-time.

## Unchecked (non-) exhaustiveness

Imagine we want to implement a function to print log messages. We can use an enum to represent different types of log levels:

```typescript
enum LogLevel { ERROR, INFO };

function log(logLevel: LogLevel, message: string) {
    if (logLevel === LogLevel.ERROR) {
        console.error(`ERROR: ${message}`);
    } else {
        console.info(message);
    }
}
```

This code is exhaustive. The `log` function has a dedicated code path for every possible log level. But there is no explicit check for exhaustiveness. This becomes a problem when another value is added to the enum:

```typescript
enum LogLevel { ERROR, INFO, WARNING }; // WARNING was added

function log(logLevel: LogLevel, message: string) {
    if (logLevel === LogLevel.ERROR) {
        console.error(`ERROR: ${message}`);
    } else {
        // WARNING will go into the else branch (just like INFO)
        console.info(message);
    }
}
```

The `else` branch was originally supposed to handle `INFO` messages. But it's now unintentionally processing warnings as well. This could be problematic. For example, we might use a monitoring tool that detects issues by scanning the log files. Warnings disguised as regular `INFO` messages would probably go unnoticed.

While new code is always written to correctly handle all cases, it's easy to lose this exhaustiveness later on. This is often down to changes in one part of the code requiring matching code changes elsewhere. When new developers join the team, they are not aware of these dependencies. Adding another enum and inadvertently breaking the `log` function is easy to do and hard to notice. That's why code should be written in a way that makes these gaps visible.

## Run-time checks

In untyped languages like plain JavaScript, exhaustiveness can only be fully checked at run-time. Linters can provide some basic validation as well. But with only limited code comprehension, they are unable to reliably spot every possible gap.

Run-time checks are implemented by handling each case in a dedicated branch, and raising an error in the final `else` or `default` branch:

```typescript
enum LogLevel { ERROR, INFO };

function log(logLevel: LogLevel, message: string) {
    if (logLevel === LogLevel.ERROR) {
        console.error(`ERROR: ${message}`);
    } else if (logLevel === LogLevel.INFO) {
        console.info(message);
    } else {
        // All known values have already been handled above.
        // We can only get into this else branch if someone
        // adds more LogLevel enums in the future (without
        // adding a matching else-if branch in this function).
        throw new Error(`Unexpected log level ${logLevel}`)
    }
}
```

If someone adds a new log level and tries to log something, the `log` function will fail. If this problem is not noticed during tests, it might eventually cause a production incident. However, that's still better than having warnings coming out as `INFO` messages without anyone noticing.

Run-time checks are effective but have a few downsides. Errors are only raised when an actual message is logged. This might happen only weeks after the production deployment. We also need to write a unit test for the `else` branch. This is a bit odd. By design, there is no enum value to trigger the error. If there was one, there would also be another `else-if` branch. When using TypeScript, we would need to bypass the type system and deliberately force-feed invalid data to the `log` function.

## Compile-time checks with "never"

When stepping over `if`/`else` branches that don't apply, TypeScript gains additional knowledge about the data being processed. Once we enter an `if` or `else` branch, the type has been narrowed down:

```typescript
enum LogLevel { ERROR, INFO };

function log(logLevel: LogLevel, message: string) {
    if (logLevel === LogLevel.ERROR) {
        // logLevel is known to be LogLevel.ERROR
    } else {
        // logLevel is known to be LogLevel.INFO
    }
}
```

In the `else` branch, `logLevel` is known to be `INFO`. That's because...

- it can only be `ERROR` or `INFO` (since the enum has no other values) and
- it can't be `ERROR` (because then the `if` condition would have matched and we wouldn't have gotten into the `else` branch)

If all possible values have already been covered by `if` and `else-if` branches, the data type in the final `else` branch is set to `never`:

```typescript
enum LogLevel { ERROR, INFO };

function log(logLevel: LogLevel, message: string) {
    if (logLevel === LogLevel.ERROR) {
        // logLevel is known to be LogLevel.ERROR
    } else if (logLevel === LogLevel.INFO) {
        // logLevel is known to be LogLevel.INFO
    } else {
        // logLevel is known to be never
    }
}
```

Before starting to narrow down the type, `logLevel` is known to be either `ERROR` or `INFO`. The non-matching `if` and `else-if` conditions remove `ERROR` and `INFO` from the list of possible values. When we get into the final `else` branch, all enum values have been ruled out. There are no other values left. TypeScript indicates this by setting the type to `never`. It effectively means that it can never happen. There's no way to get into the `else` branch.

If `logLevel` is `never`, the `if`/`else-if` branches must be exhaustive. This can be asserted through a `satisfies` type check:

```typescript
enum LogLevel { ERROR, INFO };

function log(logLevel: LogLevel, message: string) {
    if (logLevel === LogLevel.ERROR) {
        console.error(`ERROR: ${message}`);
    } else if (logLevel === LogLevel.INFO) {
        console.info(message);
    } else {
        logLevel satisfies never;
    }
}
```

If someone adds another log level to the enum, the data type in the `else` branch will no longer be `never` and cause a compile-time error:

```typescript
enum LogLevel { ERROR, INFO, WARNING }; // WARNING was added

function log(logLevel: LogLevel, message: string) {
    if (logLevel === LogLevel.ERROR) {
        console.error(`ERROR: ${message}`);
    } else if (logLevel === LogLevel.INFO) {
        console.info(message);
    } else {
        // logLevel is known to be WARNING (and no longer never)
        // the statement below now causes a compile-time error
        logLevel satisfies never;
    }
}
```

Adding an `else` branch with a `satisfies` check protects the `log` function from losing its exhaustiveness. But it has a few downsides as well. It makes the code a bit longer and requires yet another unit test. There is no enum value that would go into the `else` branch. We'd need to bypass the type system. And even then, test coverage tools tend to not recognize that the `else` branch is being executed.

## Compile-time checks without "never"

A shorter way to assert exhaustiveness is to use the `else` branch for the last possible enum value, and to explicitly check its type:

```typescript
enum LogLevel { ERROR, INFO };

function log(logLevel: LogLevel, message: string) {
    if (logLevel === LogLevel.ERROR) {
        console.error(`ERROR: ${message}`);
    } else {
        // assert that there's really only INFO left
        logLevel satisfies LogLevel.INFO;
        console.info(message);
    }
}
```

This approach saves a few lines of code and a unit test. It still provides the same benefits as having a separate `else` branch and checking for `never`. Adding another enum value without updating the `log` function still breaks the build:

```typescript
enum LogLevel { ERROR, INFO, WARNING }; // WARNING was added

function log(logLevel: LogLevel, message: string) {
    if (logLevel === LogLevel.ERROR) {
        console.error(`ERROR: ${message}`);
    } else {
        // logLevel is known to be INFO or WARNING, causing
        // the check below to raise a compile-time error
        logLevel satisfies LogLevel.INFO;
        console.info(message);
    }
}
```

Adding a simple `satisfies` check in the final `else` branch is a lightweight and effective way to ensure that a function's exhaustiveness is preserved at all times.

## Compile-time checks through lookups

Exhaustiveness checks with `satisfies` assert that there are enough `if`/`else` or `switch`/`case` branches to handle every possible input. Instead of checking the exhaustiveness of branches, we can also avoid `if` and `switch` statements altogether and use a simple object/map lookup instead:

```typescript
enum LogLevel { ERROR, INFO };

const LOG : Record<LogLevel, (message: string) => void> = {
    [LogLevel.ERROR]: message => {
        console.error(`ERROR: ${message}`);
    },
    [LogLevel.INFO]: message => {
        console.info(message);
    },
};

function log(logLevel: LogLevel, message: string) {
    LOG[logLevel](message);
}
```

This effectively implements a separate log function for every log level. They are stored as values in an object/map. The main `log` function itself only needs to look up the right arrow function and invoke it. There are no `if`/`else` statements, meaning the code can't become non-exhaustive.

Shared code (like sanitizing the log message) could still be implemented in the main `log` function. It might also be enough for the lookup object to just contain data (rather than arrow functions):

```typescript
enum LogLevel { ERROR, INFO };

const LOG_PREFIX: Record<LogLevel, string> = {
    [LogLevel.ERROR]: "[ERROR] ",
    [LogLevel.INFO ]: "[INFO]  ",
};

function log(logLevel: LogLevel, message: string) {
    console.log(LOG_PREFIX[logLevel] + message.trim());
}
```

This approach also simplifies the unit test. Previously, the `log` function contained `if`/`else` branches that required separate test cases. With the lookup object, there is only one path that needs to be tested.

## Dealing with non-enumerables

Instead of defining the log level as a simple enum, we might also implement it as a class. This allows us to attach additional metadata to it:

```typescript
class LogLevel {
    private constructor(
        public readonly name: string,
        public readonly index: number
    ) { }
    public static ERROR = new LogLevel("ERROR", 0);
    public static INFO  = new LogLevel("INFO" , 1);
}
```

Making the constructor `private` prevents other instances from being created outside of the class. This means that there is only a finite number of log levels. Any `LogLevel` instance can only be `LogLevel.ERROR` or `LogLevel.INFO`.

However, TypeScript does not treat individual class instances as a dedicated and distinguishable data type. Comparing the `logLevel` parameter with known values does not narrow down the type:

```typescript
function log(logLevel: LogLevel, message: string) {
    if (logLevel === LogLevel.ERROR) {
        // logLevel is known to be of type LogLevel
    } else {
        // logLevel is known to be of type LogLevel
    }
}
```

Only enums and union types (like `string | number`) can be checked for exhaustiveness via `satisfies`. When dealing with class instances, it's safest to avoid `if`/`else` and `switch`/`case` branches altogether. Instead, all instance-specific data and functions can be embedded into the class itself:

```typescript
class LogLevel {
    private constructor(
        public readonly name: string,
        public readonly index: number,
        public readonly prefix: string, // additional data
        public readonly print: (message: string) => void
    ) { }

    public static ERROR = new LogLevel("ERROR", 0, "🔴", console.error);
    public static INFO  = new LogLevel("INFO" , 1, "🟢", console.log  );
}

function log(logLevel: LogLevel, message: string) {
    logLevel.print(`${logLevel.prefix} ${message}`);
}
```

The `log` function no longer needs an `if`/`else` statement and can't become non-exhaustive. The `LogLevel` constructor with its mandatory parameters makes sure that every log level that's added in the future has all relevant data. The constructor does not even need to be `private`. Even random `LogLevel` instances created at runtime would be handled correctly by the `log` function.
