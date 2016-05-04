
function sayhello() void
{
    print("hello!\n");
}


function main() int
{
    thread(sayhello,  5);  
    return 0;
}
