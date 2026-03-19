package backend;

import haxe.io.Bytes;

import openfl.utils.AssetType;
import openfl.display.BitmapData;
import openfl.Assets;

#if (MODS_ALLOWED || ASSET_REDIRECT)
import sys.FileSystem;
import sys.io.File;
#end

/**
 * backend for retrieving and caching assets
 */
@:nullSafety(Strict)
class FunkinAssets
{
	static inline final MODS_PREFIX:String = 'mods/';
	static var assetPathLookup:Null<Map<String, String>> = null;
	static var assetPathLookupCount:Int = -1;
	
	static inline function normalizePath(path:String):String
	{
		if (path == null) return '';
		
		var normalized = path.replace('\\', '/').trim();
		
		while (normalized.startsWith('./'))
		{
			normalized = normalized.substr(2);
		}
		
		if (normalized.startsWith('/'))
		{
			normalized = normalized.substr(1);
		}
		
		while (normalized.contains('//'))
		{
			normalized = normalized.replace('//', '/');
		}
		
		return normalized;
	}
	
	static function getAssetPathLookup():Map<String, String>
	{
		final list = Assets.list();
		var lookup = assetPathLookup;
		
		if (lookup == null || assetPathLookupCount != list.length)
		{
			lookup = [];
			assetPathLookupCount = list.length;
			
			for (assetPath in list)
			{
				final normalized = normalizePath(assetPath).toLowerCase();
				if (!lookup.exists(normalized))
				{
					lookup.set(normalized, assetPath);
				}
			}
			
			assetPathLookup = lookup;
		}
		
		return lookup;
	}
	
	static function getAssetCandidates(path:String):Array<String>
	{
		final normalized = normalizePath(path).trim();
		final candidates:Array<String> = [];
		
		inline function pushCandidate(candidate:String):Void
		{
			if (candidate != null && candidate.length > 0 && !candidates.contains(candidate))
			{
				candidates.push(candidate);
			}
		}
		
		pushCandidate(path);
		pushCandidate(normalized);
		
		if (normalized.startsWith(MODS_PREFIX))
		{
			pushCandidate(normalized.substr(MODS_PREFIX.length));
		}
		else
		{
			pushCandidate(MODS_PREFIX + normalized);
		}
		
		return candidates;
	}
	
	static function resolveAssetPath(path:String, ?type:AssetType):Null<String>
	{
		for (candidate in getAssetCandidates(path))
		{
			if (Assets.exists(candidate, type)) return candidate;
			if (Assets.exists(candidate)) return candidate;
			
			final mappedPath = getAssetPathLookup().get(normalizePath(candidate).toLowerCase());
			if (mappedPath == null) continue;
			
			if (Assets.exists(mappedPath, type)) return mappedPath;
			if (Assets.exists(mappedPath)) return mappedPath;
		}
		
		return null;
	}
	
	static function getAssetDirectoryPrefixes(directory:String):Array<String>
	{
		final normalized = normalizePath(directory).trim();
		final prefixes:Array<String> = [];
		
		inline function pushPrefix(prefix:String):Void
		{
			if (prefix == null) return;
			
			prefix = prefix.trim();
			if (!prefixes.contains(prefix)) prefixes.push(prefix);
		}
		
		pushPrefix(directory);
		pushPrefix(normalized);
		
		if (normalized.startsWith(MODS_PREFIX))
		{
			pushPrefix(normalized.substr(MODS_PREFIX.length));
		}
		else
		{
			pushPrefix(MODS_PREFIX + normalized);
		}
		
		return prefixes;
	}
	
	/**
	 * Safer alternative to directly using `haxe.Json.parse`
	 */
	public static function parseJson(content:String, ?pos:haxe.PosInfos):Null<Any>
	{
		try
		{
			return haxe.Json.parse(content);
		}
		catch (e)
		{
			trace('failed to parse content\nException: ${e.message}', pos);
			return null;
		}
	}
	
	/**
	 * Parses a json using the json5 format.
	 */
	public static function parseJson5(content:String, ?pos:haxe.PosInfos):Null<Any>
	{
		try
		{
			#if json5hx
			return haxe.Json5.parse(content);
			#else
			return haxe.Json.parse(content);
			#end
		}
		catch (e)
		{
			trace('failed to parse content\nException: ${e.message}', pos);
			return null;
		}
	}
	
	/**
	 * Retrieves the Bytes of a given file from its path
	 */
	public static function getBytes(path:String):Bytes
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(path)) return File.getBytes(path);
		#end
		
		final assetPath = resolveAssetPath(path);
		if (assetPath != null) return Assets.getBytes(assetPath);
		else
		{
			throw 'Couldnt find file at path [$path]';
		}
	}
	
	/**
	 * Retrieves the content of a given file from its path
	 */
	public static function getContent(path:String):String
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(path)) return File.getContent(path);
		#end
		
		final assetPath = resolveAssetPath(path);
		if (assetPath != null) return Assets.getText(assetPath);
		
		throw 'Couldnt find file at path [$path]';
	}
	
	/**
	 * Retrives a bitmap instance from path.
	 * 
	 * Will return null in the case it cannot be found.
	 */
	public static function getBitmapData(path:String, useCache:Bool = true):Null<BitmapData>
	{
		var bitmap:Null<BitmapData> = null;
		#if (MODS_ALLOWED || ASSET_REDIRECT) if (FileSystem.exists(path)) bitmap = BitmapData.fromFile(path);
		else #end
		{
			final assetPath = resolveAssetPath(path, IMAGE);
			if (assetPath != null) bitmap = Assets.getBitmapData(assetPath, useCache);
		}
		
		return bitmap;
	}
	
	/**
	 *	Returns whether a given path exists.
	 */
	public static function exists(path:String, ?type:AssetType):Bool
	{
		var exists:Bool = false;
		
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(path)) exists = true;
		else
		#end
		if (resolveAssetPath(path, type) != null) exists = true;
		
		return exists;
	}
	
	/**
	 * Reads a given directory and returns all file names inside.
	 * 
	 * if it could not be found, an empty array will be returned.
	 */
	public static function readDirectory(directory:String):Array<String>
	{
		if (directory == null || directory.trim().length == 0) return [];
		
		var entries:Array<String> = [];
		
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(directory) && FileSystem.isDirectory(directory))
		{
			for (entry in FileSystem.readDirectory(directory))
			{
				if (!entries.contains(entry)) entries.push(entry);
			}
		}
		#end
		
		for (prefix in getAssetDirectoryPrefixes(directory))
		{
			var targetPrefix = normalizePath(prefix);
			if (!targetPrefix.endsWith('/')) targetPrefix += '/';
			final targetPrefixLower = targetPrefix.toLowerCase();
			
			for (path in Assets.list())
			{
				final normalizedPath = normalizePath(path);
				final normalizedPathLower = normalizedPath.toLowerCase();
				
				if (!normalizedPathLower.startsWith(targetPrefixLower) || normalizedPathLower == targetPrefixLower) continue;
				
				final remainder = normalizedPath.substr(targetPrefix.length);
				final slashIndex = remainder.indexOf('/');
				final entryName = slashIndex == -1 ? remainder : remainder.substr(0, slashIndex);
				
				if (entryName.length > 0 && !entries.contains(entryName))
				{
					entries.push(entryName);
				}
			}
		}
		
		return entries;
	}
	
	public static function isDirectory(directory:String):Bool
	{
		if (directory == null || directory.trim().length == 0) return false;
		
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(directory) && FileSystem.isDirectory(directory))
		{
			return true;
		}
		#end
		
		for (prefix in getAssetDirectoryPrefixes(directory))
		{
			var targetPrefix = normalizePath(prefix);
			if (!targetPrefix.endsWith('/')) targetPrefix += '/';
			final targetPrefixLower = targetPrefix.toLowerCase();
			
			for (path in Assets.list())
			{
				if (normalizePath(path).toLowerCase().startsWith(targetPrefixLower)) return true;
			}
		}
		
		return false;
	}
}