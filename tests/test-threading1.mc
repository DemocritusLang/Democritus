
function sayhello(noop starvoid) starvoid
{
    let x starvoid;
    print("hello!\n");
    return x;
}


function main() int
{
    let x starvoid;
    thread("sayhello", x, 5);
    return 0;
}
