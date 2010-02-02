package {
      import org.flowplayer.controls.Controls;
      import org.flowplayer.content.Content;
//    import org.flowplayer.akamai.AkamaiConnectionProvider;
      import org.flowplayer.rtmp.RTMPStreamProvider;
//    import org.flowplayer.pseudostreaming.PseudoStreamProvider;
//    import org.flowplayer.audio.AudioProvider;
//    import org.flowplayer.captions.Caption;
//    import org.flowplayer.securestreaming.SecureStreaming;
//    import org.flowplayer.smil.SmilResolver;
      //import org.flowplayer.bwcheck.BwProvider;
      import org.flowplayer.cluster.ClusterConnectionProvider;
	  import com.pistolmedia.clipresolver.ClipResolverProvider;

    public class BuiltInConfig {
          //private var controls:org.flowplayer.controls.Controls;
//        private var rtmp:org.flowplayer.rtmp.RTMPStreamProvider;
         private var controls:org.flowplayer.controls.Controls;
         private var content:org.flowplayer.content.Content;
		 // private var bufferInfo:org.flowplayer.content.Content;
		 // private var bwCheckInfo:org.flowplayer.content.Content;	
		 // private var info:org.flowplayer.content.Content;	
//        private var akamai:org.flowplayer.akamai.AkamaiConnectionProvider;
          private var rtmp:org.flowplayer.rtmp.RTMPStreamProvider;
//        private var pseudostreaming:org.flowplayer.pseudostreaming.PseudoStreamProvider;
//        private var audio:org.flowplayer.audio.AudioProvider;
//        private var captions:org.flowplayer.captions.Caption;
//        private var securestreaming:org.flowplayer.securestreaming.SecureStreaming;
//        private var smil:org.flowplayer.smil.SmilResolver;
		//private var content:org.flowplayer.content.Content;
         //private var bwcheck:org.flowplayer.bwcheck.BwProvider;
          private var cluster:org.flowplayer.cluster.ClusterConnectionProvider;
          private var resolver:com.pistolmedia.clipresolver.ClipResolverProvider;
		
		//public static const netConnectionUrl:String = "rtmp://flash.pistolmedia.xxx-xxx-xxx.net/feedVOD";
		
		public static const hosts:Array = [
			{host:"rtmp://fms2.pistolmedia.com/vod"}
		];
		
		
		/*
		
		 public static const hosts:Array = [
			{host:"rtmp://fms2.pistolmedia.com/vod"}
		]; 
		public static const hosts:Array = [
			{host:"rtmp://flash.pistolmedia.xxx-xxx-xxx.net/paysiteVOD"},
			{host:"rtmp://flash02.pistolmedia.xxx-xxx-xxx.net/paysiteVOD"}
		];		
		public static const hosts:Array = [
			{host:"rtmp://flash.hardgayfeeds.com/feedVOD"},
			{host:"rtmp://flash02.hardgayfeeds.com/feedVOD"}
		];
		 
		public static const hosts:Array = [
			{host:"rtmp://flash.pistolmedia.xxx-xxx-xxx.net/paysiteVOD"},
			{host:"rtmp://flash02.pistolmedia.xxx-xxx-xxx.net/paysiteVOD"}
		];
		public static const hosts:Array = [
			{host:"rtmp://flash.pistolmedia.xxx-xxx-xxx.net/snaps"},
			{host:"rtmp://flash02.pistolmedia.xxx-xxx-xxx.net/snaps"}
		];
		
		
		
		
		
		public static const hosts:Array = [
			{host:"rtmp://flash.pistolmedia.xxx-xxx-xxx.net/snaps"},
			{host:"rtmp://flash02.pistolmedia.xxx-xxx-xxx.net/snaps"}
		];*/
		
        public static const config:Object = {
            "plugins":{
                 "controls":{"url":"org.flowplayer.controls.Controls"},
                  content: { url: "org.flowplayer.content.Content" },
//                akamai: { url: "org.flowplayer.akamai.AkamaiConnectionProvider" },
                  "rtmp": { "url": "org.flowplayer.rtmp.RTMPStreamProvider"},
//                pseudostreaming: { url: "org.flowplayer.pseudostreaming.PseudoStreamProvider" },
//                audio: { url: "org.flowplayer.audio.AudioProvider" },
//                captions: { url: "org.flowplayer.captions.Caption", captionTarget: 'content' }
//                securestreaming: { url: "org.flowplayer.securestreaming.SecureStreaming" },
//                smil: { url: "org.flowplayer.smil.SmilResolver" }
                  "cluster": { "url": "org.flowplayer.cluster.ClusterConnectionProvider", "hosts": hosts},
                  //"bwcheck": { "url": "org.flowplayer.bwcheck.BwProvider","hosts": hosts, "serverType": "fms"  },
				  /*"bufferInfo": {"url": "org.flowplayer.content.Content"},
				  "bwCheckInfo": {"url": "org.flowplayer.content.Content"},*/
				  //info: {url: "org.flowplayer.content.Content"},
				  "resolver": {"url" : "com.pistolmedia.clipresolver.ClipResolverProvider"} 
                }
            }
        }
    }