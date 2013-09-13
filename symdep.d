/**
 * Simple tool for making object file symbol dependency graphs, so that we can
 * track down what's causing the template bloat in D executables.
 */

import std.conv;
import std.process;
import std.range;
import std.stdio;

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
    import std.typecons : Tuple, tuple;

    struct Result
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
            reSymDep = regex(`<([^>+]+)(?:+(?:0x)?[0-9a-f]+)>`);
            getNext();
        }

        // Range API
        @property bool empty() { return src.empty; }
        @property auto front() { return tuple(curSym, curDep); }
        void popFront() { getNext(); }

        private void getNext()
        {
            while (!src.empty)
            {
                auto m = src.front.match(reSymDef);
                if (m)
                {
                    curSym = to!string(m.captures[1]);
                }
                else
                {
                    auto m = src.front.match(reSymDep);
                    if (m)
                    {
                        curDep = to!string(m.captures[1]);
                        break;
                    }
                }
                src.popFront();
            }
        }
    }
    return Result(lines);
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
