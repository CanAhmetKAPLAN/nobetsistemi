namespace NobetSistemi.Domain.Exceptions;

public class AppException : Exception
{
    public int StatusCode { get; }

    public AppException(string message, int statusCode = 400) : base(message)
    {
        StatusCode = statusCode;
    }
}

public class NotFoundException : AppException
{
    public NotFoundException(string message) : base(message, 404) { }
}

public class UnauthorizedException : AppException
{
    public UnauthorizedException(string message = "Yetkisiz erişim.") : base(message, 401) { }
}

public class ConflictException : AppException
{
    public ConflictException(string message) : base(message, 409) { }
}
