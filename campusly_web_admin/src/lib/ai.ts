import { GoogleGenAI, Type, Schema } from '@google/genai';

const getAi = () => {
  const apiKey = import.meta.env.VITE_GEMINI_API_KEY;
  if (!apiKey) throw new Error("VITE_GEMINI_API_KEY is not set in environment variables");
  return new GoogleGenAI({ apiKey });
};

const curriculumSchema: Schema = {
  type: Type.OBJECT,
  properties: {
    regulation: {
      type: Type.OBJECT,
      properties: {
        name: { type: Type.STRING },
        regulation_year: { type: Type.INTEGER },
        batch: { type: Type.STRING },
        effective_academic_year: { type: Type.STRING }
      },
      required: ["name", "regulation_year", "batch", "effective_academic_year"]
    },
    semesters: {
      type: Type.ARRAY,
      items: {
        type: Type.OBJECT,
        properties: {
          semester_number: { type: Type.INTEGER },
          subjects: {
            type: Type.ARRAY,
            items: {
              type: Type.OBJECT,
              properties: {
                subject_code: { type: Type.STRING },
                name: { type: Type.STRING },
                credits: { type: Type.NUMBER },
                course_type: { type: Type.STRING },
                l_t_p: { type: Type.STRING },
                theory_lab: { type: Type.STRING },
                category: { type: Type.STRING }
              },
              required: ["subject_code", "name", "credits"]
            }
          }
        },
        required: ["semester_number", "subjects"]
      }
    }
  },
  required: ["regulation", "semesters"]
};

export async function extractCurriculumFromPDF(base64Data: string) {
  try {
    const ai = getAi();
    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: [
        {
          role: 'user',
          parts: [
            {
              inlineData: {
                data: base64Data,
                mimeType: 'application/pdf'
              }
            },
            {
              text: `You are an expert academic curriculum parser. 
Analyze the provided PDF curriculum document and extract all structured data according to the schema provided. 
Extract every semester and every subject.
Ensure course codes, credits, and L-T-P (Lecture-Tutorial-Practical) structures are extracted accurately.
Identify whether courses are Theory or Lab, Professional Core or Elective.
If books or outcomes are mentioned per subject, extract them.
Return ONLY valid JSON matching the schema.`
            }
          ]
        }
      ],
      config: {
        responseMimeType: 'application/json',
        responseSchema: curriculumSchema,
        temperature: 0.1
      }
    });

    if (!response.text) {
        throw new Error("No text returned from Gemini");
    }
    
    return JSON.parse(response.text);
  } catch (error) {
    console.error("AI Extraction failed:", error);
    throw error;
  }
}
