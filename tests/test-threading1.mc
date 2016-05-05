
function sayhello(noop int) void
{
    print("hello!\n");
}


function main() int
{
    thread("sayhello", 0, 5);
    return 0;
}
