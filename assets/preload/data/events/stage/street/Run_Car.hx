
preset("defaultValues", []);

function execute():Void {
    getState().stage.script.call("run_car", []);
}