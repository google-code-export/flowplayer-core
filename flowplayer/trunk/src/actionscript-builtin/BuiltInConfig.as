package {
    import org.flowplayer.rtmp.RTMPStreamProvider;
    import org.flowplayer.controls.Controls;

    public class BuiltInConfig {
        private var rtmp:org.flowplayer.rtmp.RTMPStreamProvider;
//        private var controls:org.flowplayer.controls.Controls;

        public static const config:Object = {
            plugins:{
                rtmp: {
                    url: "org.flowplayer.rtmp.RTMPStreamProvider",
                    netConnectionUrl: 'rtmp://cyzy7r959.rtmphost.com/flowplayer'
                }
            },
            play: {
                replayLabel: 'Replay'
            }
        }
    }
}