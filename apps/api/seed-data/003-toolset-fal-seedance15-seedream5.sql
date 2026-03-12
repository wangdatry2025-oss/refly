-- Remove old fal tool methods (keep fal-image-to-video)
DELETE FROM tool_methods WHERE "name" IN (
    'fal-voice-clone',
    'fal-text-to-podcast',
    'fal-text-to-speech',
    'flux_image_to_image',
    'flux_text_to_image'
);

-- Remove old fal_audio toolset inventory and toolset (no longer needed)
DELETE FROM toolsets WHERE "key" = 'fal_audio';
DELETE FROM toolset_inventory WHERE "key" = 'fal_audio';

-- Update fal_video inventory: billing for both video tools
UPDATE toolset_inventory
SET credit_billing = '{"fal-text-to-video":20,"fal-image-to-video":20}',
    description_dict = '{"en":"Generate videos with Seedance models. Support text-to-video and image-to-video generation with high quality audio output.","zh-CN":"使用 Seedance 模型生成视频。支持文生视频和图生视频，输出高质量带音频视频。"}'
WHERE "key" = 'fal_video' AND deleted_at IS NULL;

-- Update fal_image inventory: replace billing with only seedream_text_to_image
UPDATE toolset_inventory
SET credit_billing = '{"seedream_text_to_image":{"enabled":true,"type":"per_quantity","quantityField":"num_images","creditsPerUnit":2}}',
    description_dict = '{"en":"Generate images with Seedream 5.0 model. Support text-to-image generation with high quality output up to 2K.","zh-CN":"使用 Seedream 5.0 模型生成图像。支持文生图，输出高质量 2K 图像。"}'
WHERE "key" = 'fal_image' AND deleted_at IS NULL;

-- Insert new tool methods (sync fal.run mode, no polling)
INSERT INTO tool_methods (inventory_key,version_id,"name",description,endpoint,http_method,request_schema,response_schema,adapter_type,adapter_config,enabled,deleted_at) VALUES
	 ('fal_video',1,'fal-text-to-video','Text-to-Video generation with audio using Bytedance Seedance 1.5 Pro model. Generate high-quality videos with synchronized audio from text prompts only - no input image required. Supports 4-12 second duration, multiple aspect ratios and resolutions. Describe the desired scene, motion, visual style, and audio/dialogue elements in the prompt.','https://fal.run/fal-ai/bytedance/seedance/v1.5/pro/text-to-video','POST','{"type":"object","description":"Text-to-Video generation with audio using Bytedance Seedance 1.5 Pro model. Generate high-quality videos with synchronized audio from text prompts. No input image required.","properties":{"prompt":{"type":"string","description":"REQUIRED. The text prompt used to generate the video. Describe the desired scene, motion, characters, visual style, and audio/dialogue elements. For dialogue, include spoken text in quotes. Example: ''Defense attorney declaring \"Ladies and gentlemen, reasonable doubt isn''t just a phrase\", footsteps on marble, courtroom drama.''"},"aspect_ratio":{"type":"string","description":"The aspect ratio of the generated video. Options: 21:9, 16:9, 4:3, 1:1, 3:4, 9:16, auto. Default: ''16:9''","enum":["21:9","16:9","4:3","1:1","3:4","9:16","auto"],"default":"16:9"},"resolution":{"type":"string","description":"Video resolution. 480p for faster generation, 720p for balance, 1080p for higher quality. Default: ''720p''","enum":["480p","720p","1080p"],"default":"720p"},"duration":{"type":"string","description":"Duration of the video in seconds. Range: 4-12 seconds. Default: ''5''","enum":["4","5","6","7","8","9","10","11","12"],"default":"5"},"camera_fixed":{"type":"boolean","description":"Whether to fix the camera position during video generation. Set to true for stable camera, false for dynamic camera movement."},"seed":{"type":"integer","description":"Random seed to control video generation for reproducibility. Use -1 for random seed."},"enable_safety_checker":{"type":"boolean","description":"If set to true, the safety checker will be enabled to filter NSFW content. Default: true","default":true},"generate_audio":{"type":"boolean","description":"Whether to generate synchronized audio for the video. Default: true","default":true}},"required":["prompt"]}','{"type":"object","description":"Seedance 1.5 Text-to-Video API response. Contains the generated video with audio and generation metadata.","properties":{"video":{"type":"object","description":"The generated video file object","properties":{"url":{"type":"string","description":"URL to download the generated video","isResource":true,"format":"url"},"content_type":{"type":"string","description":"MIME type of the video file","default":"video/mp4"},"file_name":{"type":"string","description":"The name of the video file"},"file_size":{"type":"integer","description":"The size of the video file in bytes"}},"required":["url"]},"seed":{"type":"integer","description":"The seed value used for generation. Can be reused for reproducibility."}},"required":["video"]}','http','{"headers":{"Authorization":"Key ${apiKey}","Content-Type":"application/json"},"timeout":600000}',true,NULL),
	 ('fal_image',1,'seedream_text_to_image','Text-to-Image generation with Bytedance Seedream 5.0 Lite model. Generate high-quality images from text prompts with intelligent text rendering support. Output resolution up to 2K. Supports generating multiple images per request. No input image required - use this for creating new images from scratch.','https://fal.run/fal-ai/bytedance/seedream/v5/lite/text-to-image','POST','{"type":"object","description":"Text-to-Image generation with Bytedance Seedream 5.0 Lite model. Generate high-quality images from text prompts with intelligent text rendering. Output resolution up to 2K.","properties":{"prompt":{"type":"string","description":"REQUIRED. The text prompt to generate an image from. Be as descriptive as possible for best results. Supports intelligent text rendering - include text in quotes to render it in the image. Example: ''Realistic DSLR photograph of anthropomorphic dog enjoying ramen with the words \"Hello World\" visible at the top.''"},"image_size":{"description":"The size of the generated image. Can be a preset string or a custom object with width/height. Total pixels must be between 2560x1440 and 3072x3072. Default: ''auto_2K''","default":"auto_2K","oneOf":[{"type":"string","enum":["square_hd","square","portrait_4_3","portrait_16_9","landscape_4_3","landscape_16_9","auto_2K"],"description":"Preset image size. Default: ''auto_2K''"},{"type":"object","description":"Custom image size with explicit width and height in pixels","properties":{"width":{"type":"integer","description":"Custom width in pixels"},"height":{"type":"integer","description":"Custom height in pixels"}},"required":["width","height"]}]},"num_images":{"type":"integer","description":"Number of separate model generations to run. Range: 1-6. Default: 1","minimum":1,"maximum":6,"default":1},"max_images":{"type":"integer","description":"If greater than 1, enables multi-image generation per run. Total images will be between num_images and max_images * num_images. Range: 1-6. Default: 1","minimum":1,"maximum":6,"default":1},"enable_safety_checker":{"type":"boolean","description":"Enable NSFW content safety checker. Default: true","default":true}},"required":["prompt"]}','{"type":"object","description":"Seedream 5.0 Text-to-Image API response. Contains generated images and metadata.","properties":{"images":{"type":"array","description":"Array of generated image objects","items":{"type":"object","properties":{"url":{"type":"string","description":"URL to download the generated image","isResource":true,"format":"url"},"width":{"type":"integer","description":"Width of the generated image in pixels"},"height":{"type":"integer","description":"Height of the generated image in pixels"},"content_type":{"type":"string","description":"MIME type of the image","default":"image/png"}},"required":["url"]}},"seed":{"type":"integer","description":"The seed value used for generation. Can be reused for reproducibility."}},"required":["images"]}','http','{"headers":{"Authorization":"Key ${apiKey}","Content-Type":"application/json"},"timeout":120000}',true,NULL)
ON CONFLICT ("inventory_key", "name", "version_id") DO NOTHING;

-- Fix existing records in case they were already inserted
UPDATE tool_methods
SET endpoint = 'https://fal.run/fal-ai/bytedance/seedance/v1.5/pro/text-to-video',
    adapter_config = '{"headers":{"Authorization":"Key ${apiKey}","Content-Type":"application/json"},"timeout":600000}'
WHERE inventory_key = 'fal_video' AND "name" = 'fal-text-to-video' AND version_id = 1;

UPDATE tool_methods
SET endpoint = 'https://fal.run/fal-ai/bytedance/seedream/v5/lite/text-to-image',
    adapter_config = '{"headers":{"Authorization":"Key ${apiKey}","Content-Type":"application/json"},"timeout":120000}'
WHERE inventory_key = 'fal_image' AND "name" = 'seedream_text_to_image' AND version_id = 1;

-- Migrate fal-image-to-video to sync fal.run mode
UPDATE tool_methods
SET endpoint = 'https://fal.run/fal-ai/bytedance/seedance/v1/pro/fast/image-to-video',
    adapter_config = '{"headers":{"Authorization":"Key ${apiKey}","Content-Type":"application/json"},"timeout":600000}'
WHERE inventory_key = 'fal_video' AND "name" = 'fal-image-to-video' AND version_id = 1;
