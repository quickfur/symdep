/**
 * Simple tool for making object file symbol dependency graphs, so that we can
 * track down what's causing the template bloat in D executables.
 */

import std.conv;
import std.process;
import std.range;
import std.regex;
import std.stdio;
import std.string : splitLines;
import std.typecons : tuple;

version(unittest)
    import std.algorithm;


immutable objdump = "/usr/bin/objdump";


/**
 * Parses objdump output to extract symbol dependencies.
 *
 * Returns: An input range of Tuples containing pairs strings, representing a
 * symbol with its dependency. If a symbol depends on more than one symbol, it
 * will appear multiple times in the range, once for each dependency.
 */
auto parseSymDeps(R)(R lines)
    if (isInputRange!R && is(ElementType!R : const(char)[]))
{
    static struct Result
    {
        private R src;
        private string curSym;
        private string curDep;

        private Regex!char reSymDef; // regex to match symbol definition
        private Regex!char reSymDep; // regex to match symbol dependencies

        this(R _src)
        {
            src = _src;
            reSymDef = regex(`^[0-9a-f]+\s+<([^>]+)>:\s*$`);
            reSymDep = regex(`<([^>+]+)(?:\+(?:0x)?[0-9a-f]+)?>`);
            getNext();
        }

        // Range API
        @property bool empty() { return src.empty; }
        @property auto front() { return tuple(curSym, curDep); }
        void popFront()
        {
            src.popFront(); // skip over current match
            getNext();
        }

        private void getNext()
        {
            while (!src.empty)
            {
                // See if we're on a new symbol definition (this must be done
                // first, since reSymDep may otherwise wrongly match the name
                // of the new symbol instead of a real dependency).
                auto m = src.front.match(reSymDef);
                if (m)
                {
                    curSym = to!string(m.captures[1]);
                }
                else
                {
                    // Not a symbol definition; see if there's a dependency.
                    m = src.front.match(reSymDep);
                    if (m)
                    {
                        // Found dependency: yield.
                        curDep = to!string(m.captures[1]);
                        break;
                    }
                }
                src.popFront();
            }
        }
    }
    static assert(isInputRange!Result);

    return Result(lines);
}

unittest
{
    string[] sampleInput = splitLines(q"END
000000000049b228 <_D3std7process7__arrayZ>:
  49b228:	55                   	push   %rbp
  49b229:	48 8b ec             	mov    %rsp,%rbp
  49b22c:	48 83 ec 10          	sub    $0x10,%rsp
  49b230:	48 89 fe             	mov    %rdi,%rsi
  49b233:	48 bf c0 5d 6e 00 00 	movabs $0x6e5dc0,%rdi
  49b23a:	00 00 00 
  49b23d:	e8 7e a6 ff ff       	callq  4958c0 <_d_array_bounds>
  49b242:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
END");
    auto deps = parseSymDeps(sampleInput);
    assert(deps.equal([
        tuple("_D3std7process7__arrayZ", "_d_array_bounds")
    ]));
}

void buildSymGraph(R)(R lines)
    if (isInputRange!R && is(ElementType!R : const(char)[]))
{
}

int main(string[] args)
{
    try
    {
        if (args.length < 2)
        {
            writeln("Please specify object file or executable to graph");
            return 1;
        }
        string objfile = args[1]; 

        auto child = pipeProcess([objdump, "-D", objfile], Redirect.stdout);
        buildSymGraph(child.stdout.byLine);

        auto status = wait(child.pid);
        if (status != 0)
            throw new Exception("objdump exited with status " ~
                                to!string(status));
    }
    catch(Exception e)
    {
        writeln("Error: ", e.msg);
        return 2;
    }
    return 0;
}

// vim:ai ts=4 sw=4 et:
