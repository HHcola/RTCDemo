package io.agora.faceu;

public class HardCodeData {
    public static class EffectItem {
        public String name;
        public int type;
        public String unzipPath;

        public EffectItem(String name, int type, String unzipPath) {
            this.name = name;
            this.type = type;
            this.unzipPath = unzipPath;
        }
    }

    public static EffectItem[] sItems = new EffectItem[]{
            new EffectItem("50241_2.zip", 3, "50241_2"),
            new EffectItem("20091_4_b.zip", 3, "animal_bearcry_b"),
            new EffectItem("20088_1_b.zip", 3, "animal_catfoot_b"),
            new EffectItem("20101_1.zip", 1, "animal_lujiao"),
            new EffectItem("20037_7.zip", 1, "hiphop"),
            new EffectItem("50163_1.zip", 1, "lanqiu"),
            new EffectItem("50165_1.zip", 1, "diaozhatian"),
            new EffectItem("170010_1.zip", 2, "mirrorface"),
            new EffectItem("50117_2.zip", 1, "gandong"),
            new EffectItem("50109_2.zip", 1, "weisuo"),
            new EffectItem("50204_1.zip", 1, "catking"),
            new EffectItem("50208_1.zip", 1, "menglu"),
            new EffectItem("20059_1.zip", 1, "dswd"),
            new EffectItem("50067_1.zip", 1, "maikefeng"),
            new EffectItem("50080_1.zip", 1, "dayanjing"),
            new EffectItem("30002_6.zip", 1, "discoball"),
    };

}
