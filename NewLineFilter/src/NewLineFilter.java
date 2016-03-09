import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.util.regex.Pattern;

public class NewLineFilter {

	/**
	 * @param args
	 * @throws IOException 
	 */
	public static void main(String[] args) throws IOException {

		InputStream ins = null; // raw byte-stream
		Reader r = null; // cooked reader
		BufferedReader br = null; // buffered for readLine()
		
		FileWriter writer = new FileWriter(
				"/rzone/PracticalAndroidApps/TreeWorkspace/VirginiaGPU/Data/PreRun/file.txt" );
		
		try {
			String s;
			ins = new FileInputStream("/rzone/PracticalAndroidApps/TreeWorkspace/VirginiaGPU/Data/PreRun/original_file.txt");
			r = new InputStreamReader(ins, "UTF-8"); // leave charset out for
														// default
			br = new BufferedReader(r);
			while ((s = br.readLine()) != null) {
				System.out.println(s);
				
				String out = s.replaceAll("\n", " ")
						.replaceAll("\t", " ");
				writer.write(clean(out));
			}
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

	private static String clean(String out) {
		StringBuilder b = new StringBuilder();
		for( int i = 0 ; i < out.length() ; i++){
			if( out.charAt(i) >= 'a' && out.charAt(i) <= 'z' || out.charAt(i) == ' '){
				b.append(out.charAt(i));
			}
		}
		return b.toString();
	}

	Pattern P = Pattern.compile("");
}
