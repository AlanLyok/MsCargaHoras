using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace MsCargaHoras
{
    public partial class TestLABTRAC : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                txtQuery.Text = "SELECT TOP 10 name, object_id FROM sys.objects ORDER BY object_id DESC";
            }
        }

        protected void btnRun_Click(object sender, EventArgs e)
        {
            try
            {
                string connectionString = ConfigurationManager.ConnectionStrings["LABTRACConnectionString"].ConnectionString;
                using (var connection = new SqlConnection(connectionString))
                using (var command = new SqlCommand(txtQuery.Text, connection))
                using (var adapter = new SqlDataAdapter(command))
                {
                    var table = new DataTable();
                    connection.Open();
                    adapter.Fill(table);
                    grid.DataSource = table;
                    grid.DataBind();
                    lblStatus.Text = "Consulta ejecutada correctamente.";
                }
            }
            catch (Exception ex)
            {
                lblStatus.Text = "Error: " + ex.Message;
            }
        }
    }
}


