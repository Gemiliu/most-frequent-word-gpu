import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;


public class WordLength {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		InputStream ins = null; // raw byte-stream
		Reader r = null; // cooked reader
		BufferedReader br = null; // buffered for readLine()
		
		double max = Double.MIN_VALUE, min = Double.MAX_VALUE, sum = 0.0, avg = 0.0;
		int count = 0;
		try {
			String s;
			ins = new FileInputStream(
					"/rzone/PracticalAndroidApps/TreeWorkspace/VirginiaGPU/Data/PreRun/file.txt" 
					);
			r = new InputStreamReader(ins, "UTF-8"); // leave charset out for
														// default
			br = new BufferedReader(r);
			while ((s = br.readLine()) != null) {
//				System.out.println(s);
				String[] words = s.split(" ");
				for( String w : words ){
					if( max < w.length() ){
						max = w.length();
						System.out.println( w);
					}
					if(min > w.length() ){
						min = w.length();
					}
					sum += w.length();
					++count;
				}
			}
			
			avg = sum / count;
			
			System.out.println(" max: " + max + " min: " + min + " avg: " + avg );
			
		} catch (Exception e) {
			System.err.println(e.getMessage()); // handle exception
		} finally {
			if (br != null) {
				try {
					br.close();
				} catch (Throwable t) { /* ensure close happens */
				}
			}
			if (r != null) {
				try {
					r.close();
				} catch (Throwable t) { /* ensure close happens */
				}
			}
			if (ins != null) {
				try {
					ins.close();
				} catch (Throwable t) { /* ensure close happens */
				}
			}
		}
	}

}
