import java.io.FileWriter;
import java.io.IOException;
import java.util.HashSet;
import java.util.Random;
import java.util.Set;


public class VariableWordMaker {

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
		while( vocabulary.size() < 10000){
			vocabulary.add(makeWord());
		}
		
		Random r = new Random();
		
		int size = 1000;
		
		for( int j = 0; j < 16; j++){
			
			StringBuilder file_text = new StringBuilder();
			
			Vocabulary = vocabulary.toArray(new String[]{});
			
			while( file_text.length() < size ){
				file_text.append(Vocabulary[getIndex(r.nextDouble(), 0)] + " ");
			}
			
			FileWriter writer = new FileWriter(
					"/rzone/PracticalAndroidApps/TreeWorkspace/VirginiaGPU/Data/Experiment/Words/ConstLength/Fifty" + size + ".txt");
			writer.write( file_text.toString() );
			writer.close();
			
			size = size * 2;
		}
	}

	static final double C = 0.5;
	
	private static int getIndex(double d, int i) {
		if( d > ( C * Math.pow(2, i+1))){
			return i;
		}else{
			return getIndex( d, i+1);
		}
	}

	private static String makeWord() {
		int length = 8;
		Random r = new Random();
		StringBuilder b = new StringBuilder();
		for( int i =0; i < length; i++){
			b.append( letters[ r.nextInt(letters.length)]);
		}
		return b.toString();
	}

}
