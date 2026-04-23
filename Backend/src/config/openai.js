const OpenAI = require('openai');

let openaiClient;

const getOpenAIClient = () => {
  if (!openaiClient) {
    if (!process.env.GROQ_API_KEY) {
      throw new Error('GROQ_API_KEY is not defined');
    }
    openaiClient = new OpenAI({ 
      apiKey: process.env.GROQ_API_KEY,
      baseURL: 'https://api.groq.com/openai/v1' 
    });
  }
  return openaiClient;
};

module.exports = { getOpenAIClient };
