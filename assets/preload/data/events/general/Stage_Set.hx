
preset("defaultValues", [
    { name: "Name", type: "String", value: "Stage" }
]);

function execute(_name:String):Void {
    getState().stage.load(_name);
}