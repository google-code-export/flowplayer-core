package {
    import org.flowplayer.controls.Controls;
    import org.flowplayer.content.Content;
    public class BuiltInConfig {
        private var controls:org.flowplayer.controls.Controls;
        private var content:org.flowplayer.content.Content;

        public static const config:Object = {"plugins":{
            "controls":{"url":"org.flowplayer.controls.Controls"},
            content: { url: "org.flowplayer.content.Content" }
        }}
    }
}