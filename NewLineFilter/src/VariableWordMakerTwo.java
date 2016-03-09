import java.io.FileWriter;
import java.io.IOException;
import java.util.HashSet;
import java.util.Random;
import java.util.Set;


public class VariableWordMakerTwo {

	static String[] Vocabulary;
	
	static String[] letters = new String[]{
			"a", "b", "c", "d", "e", "f", 
			"g", "h", "i", "j", "k", "l", 
			"m", "n", "o", "p", "q", "r", 
			"s", "t", "u", "v", "w","x", "y", "z"};	
	
	/**
	 * @param args
	 * @throws IOException 
	 */
	public static void main(String[] args) throws IOException {
		Set<String> vocabulary = new HashSet<String>();
		Random r = new Random();
		while( vocabulary.size() < 40000){
			vocabulary.add(makeWord(r));
		}
		double[] c = {0.5, 0.1, 0.9};
		String[] folder = {"Fifty", "Ten", "Ninety"};
		
		Vocabulary = vocabulary.toArray(new String[]{});
		
		for( int k = 0; k < 3; k++){
			
			System.out.println("k " + k);
			int size = 1000;	
			for( int j = 0; j < 16; j++){
				
				StringBuilder file_text = new StringBuilder();
	
				while( file_text.length() < size ){
					file_text.append(Vocabulary[getIndex(c[k], r.nextDouble(), 0)] + " ");
				}
				
				FileWriter writer = new FileWriter(
						"/rzone/PracticalAndroidApps/TreeWorkspace/" +
						"VirginiaGPU/Data/Experiment/Words/VariableLength/" 
								+ folder[k] + "/" + size + ".txt");
				writer.write( file_text.toString() );
				writer.close();
				
				size = size * 2;
			}
		}
	}

	static final double C = 0.5;
	
	private static int getIndex(double c, double d, int i) {
		if( d > ( Math.pow(c,  i+1))){
			return i;
		}else{
//			System.out.println( "val: " + d + " " + Math.pow(c,  i+1)) ;
			return getIndex(c, d, i+1);
		}
	}

	private static String makeWord(Random r) {
		StringBuilder b = new StringBuilder();
		int length = r.nextInt(16) + 2;
		for( int i =0; i < length; i++){
			b.append( letters[ r.nextInt(letters.length)]);
		}
		return b.toString();
	}

}
