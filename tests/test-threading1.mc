
function sayhello(noop starvoid) starvoid
{
    let x starvoid;
    print("hello!\n");
    return x;
}


function main() int
{
    thread("sayhello", 0, 5);
    return 0;
}
